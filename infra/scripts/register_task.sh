#!/bin/bash
set -euo pipefail

: "${IMAGE_URI:?Missing IMAGE_URI}"
: "${AWS_REGION:?Missing AWS_REGION}"

echo "==> Registering new task definition..."

# Load base task definition
TASK_DEF_JSON=$(cat infra/terraform/task-definition.json)

# Inject new image
NEW_TASK_DEF=$(echo "$TASK_DEF_JSON" | jq \
  --arg IMAGE "$IMAGE_URI" \
  '.containerDefinitions[0].image = $IMAGE
  | del(
      .taskDefinitionArn,
      .revision,
      .status,
      .requiresAttributes,
      .compatibilities,
      .registeredAt,
      .registeredBy
    )')

# Register task definition
TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json "$NEW_TASK_DEF" \
  --query "taskDefinition.taskDefinitionArn" \
  --output text \
  --region "$AWS_REGION")

echo "==> Registered task definition:"
echo "$TASK_DEF_ARN"

# Export for GitHub Actions
echo "TASK_DEF_ARN=$TASK_DEF_ARN" >> $GITHUB_ENV