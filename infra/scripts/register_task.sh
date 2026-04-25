#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE_URI:?Missing}"
: "${AWS_REGION:?Missing}"
: "${DEPLOY_SERVICE:?Missing}"

echo "Registering new task definition with image: $IMAGE_URI"

TASK_FAMILY="$DEPLOY_SERVICE"

RAW=$(aws ecs describe-task-definition \
  --task-definition "$TASK_FAMILY" \
  --region "$AWS_REGION")

UPDATED=$(echo "$RAW" | jq \
  --arg IMAGE "$IMAGE_URI" '
  .taskDefinition
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

NEW_TASK_DEF=$(aws ecs register-task-definition \
  --cli-input-json "$UPDATED" \
  --query "taskDefinition.taskDefinitionArn" \
  --output text)

echo "task_def_arn=$NEW_TASK_DEF" >> $GITHUB_OUTPUT