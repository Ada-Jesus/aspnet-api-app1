#!/usr/bin/env bash
set -eo pipefail

: "${DEPLOY_SERVICE:?Missing DEPLOY_SERVICE}"
: "${IMAGE_URI:?Missing IMAGE_URI}"
: "${AWS_REGION:?Missing AWS_REGION}"

echo "==> Fetching task definition for: ${DEPLOY_SERVICE}"

TASK_DEF_ARN=$(aws ecs describe-services \
  --services "$DEPLOY_SERVICE" \
  --cluster "$ECS_CLUSTER" \
  --query "services[0].taskDefinition" \
  --output text \
  --region "$AWS_REGION")

echo "    Current TD: $TASK_DEF_ARN"
echo "    New image:  $IMAGE_URI"

# Get full task definition JSON
TASK_DEF_JSON=$(aws ecs describe-task-definition \
  --task-definition "$TASK_DEF_ARN" \
  --region "$AWS_REGION")

# Clean + replace image
NEW_TASK_DEF=$(echo "$TASK_DEF_JSON" | jq \
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

# Register new task definition
NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json "$NEW_TASK_DEF" \
  --query "taskDefinition.taskDefinitionArn" \
  --output text \
  --region "$AWS_REGION")

echo "==> New task definition: $NEW_TASK_DEF_ARN"

# Output for next steps
echo "task_def_arn=$NEW_TASK_DEF_ARN" >> "$GITHUB_OUTPUT"