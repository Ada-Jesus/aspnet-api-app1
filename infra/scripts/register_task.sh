#!/bin/bash
set -euo pipefail

: "${IMAGE_URI:?Missing IMAGE_URI}"
: "${AWS_REGION:?Missing AWS_REGION}"

echo "==> Registering ECS task definition..."

TASK_DEF_FILE="$(pwd)/infra/terraform/task-definition.json"

if [ ! -f "$TASK_DEF_FILE" ]; then
  echo "Task definition not found: $TASK_DEF_FILE"
  exit 1
fi

TASK_JSON=$(cat "$TASK_DEF_FILE")

NEW_TASK=$(echo "$TASK_JSON" | jq \
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

TASK_ARN=$(aws ecs register-task-definition \
  --cli-input-json "$NEW_TASK" \
  --query "taskDefinition.taskDefinitionArn" \
  --output text \
  --region "$AWS_REGION")

echo "TASK_DEF_ARN=$TASK_ARN" >> $GITHUB_ENV
echo "Registered: $TASK_ARN"