#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════
# REQUIRED ENV
# ═══════════════════════════════════════════════
: "${AWS_REGION:?Missing AWS_REGION}"
: "${ECS_CLUSTER:?Missing ECS_CLUSTER}"
: "${BLUE_SERVICE:?Missing BLUE_SERVICE}"
: "${GREEN_SERVICE:?Missing GREEN_SERVICE}"
: "${IMAGE_URI:?Missing IMAGE_URI}"

echo "==> Starting stable blue/green deployment"

# ═══════════════════════════════════════════════
# STEP 1 - DETECT ACTIVE SLOT (STABLE LOGIC)
# ═══════════════════════════════════════════════
BLUE_COUNT=$(aws ecs describe-services \
  --cluster "$ECS_CLUSTER" \
  --services "$BLUE_SERVICE" \
  --query "services[0].desiredCount" \
  --output text)

if [ "$BLUE_COUNT" -gt 0 ]; then
  LIVE="$BLUE_SERVICE"
  DEPLOY="$GREEN_SERVICE"
else
  LIVE="$GREEN_SERVICE"
  DEPLOY="$BLUE_SERVICE"
fi

echo "Live service: $LIVE"
echo "Deploy service: $DEPLOY"

# ═══════════════════════════════════════════════
# STEP 2 - GET TASK DEFINITION + UPDATE IMAGE
# ═══════════════════════════════════════════════
TASK_DEF_ARN=$(aws ecs describe-task-definition \
  --task-definition aspnet-api-production \
  --query "taskDefinition.taskDefinitionArn" \
  --output text)

NEW_TASK_DEF=$(aws ecs describe-task-definition \
  --task-definition "$TASK_DEF_ARN")

UPDATED_TASK_DEF=$(echo "$NEW_TASK_DEF" | jq \
  --arg IMAGE "$IMAGE_URI" \
  '.taskDefinition
   | .containerDefinitions[0].image = $IMAGE
   | del(
      .taskDefinitionArn,
      .revision,
      .status,
      .requiresAttributes,
      .compatibilities,
      .registeredAt,
      .registeredBy
   )')

NEW_REVISION=$(aws ecs register-task-definition \
  --cli-input-json "$UPDATED_TASK_DEF" \
  --query "taskDefinition.taskDefinitionArn" \
  --output text)

echo "New task definition: $NEW_REVISION"

# ═══════════════════════════════════════════════
# STEP 3 - DEPLOY NEW SLOT
# ═══════════════════════════════════════════════
aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$DEPLOY" \
  --task-definition "$NEW_REVISION" \
  --desired-count 1 \
  --force-new-deployment \
  --region "$AWS_REGION"

echo "==> Waiting for service stability..."
aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$DEPLOY"

# ═══════════════════════════════════════════════
# STEP 4 - HEALTH CHECK (GATE)
# ═══════════════════════════════════════════════
ALB_DNS="${ALB_DNS_NAME:-}"

if [ -z "$ALB_DNS" ]; then
  echo "WARNING: ALB_DNS_NAME not set, skipping health check"
  exit 0
fi

URL="http://${ALB_DNS}/health"

echo "==> Health check: $URL"

for i in {1..10}; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || echo "000")

  if [ "$CODE" = "200" ]; then
    echo "Healthy on attempt $i"
    break
  fi

  echo "Attempt $i failed ($CODE)"
  sleep 5

  if [ "$i" -eq 10 ]; then
    echo "❌ HEALTH CHECK FAILED → ROLLBACK STARTING"

    aws ecs update-service \
      --cluster "$ECS_CLUSTER" \
      --service "$DEPLOY" \
      --desired-count 0

    exit 1
  fi
done

# ═══════════════════════════════════════════════
# STEP 5 - TRAFFIC SWITCH (FINAL CUTOVER)
# ═══════════════════════════════════════════════
aws elbv2 modify-listener \
  --listener-arn "$ALB_LISTENER_ARN" \
  --default-actions "Type=forward,TargetGroupArn=${DEPLOY_TG_ARN}"

# ═══════════════════════════════════════════════
# STEP 6 - SCALE DOWN OLD SLOT
# ═══════════════════════════════════════════════
aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$LIVE" \
  --desired-count 0

echo "==> Deployment completed successfully"