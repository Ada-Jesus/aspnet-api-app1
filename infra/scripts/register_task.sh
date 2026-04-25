#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE_URI:?Missing IMAGE_URI}"
: "${AWS_REGION:?Missing AWS_REGION}"

TASK_FAMILY="aspnet-api-production"

echo "==> Registering task definition for $TASK_FAMILY"

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

TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json "$UPDATED" \
  --region "$AWS_REGION" \
  --query "taskDefinition.taskDefinitionArn" \
  --output text)

echo "task_def_arn=$TASK_DEF_ARN" >> "$GITHUB_OUTPUT"