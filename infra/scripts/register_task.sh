#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE_URI:?Missing IMAGE_URI}"
: "${AWS_REGION:?Missing}"

echo "Registering task definition with image: $IMAGE_URI"

TASK=$(aws ecs describe-task-definition \
  --task-definition aspnet-api-production:5 \
  --region "$AWS_REGION")

echo "$TASK" | jq --arg IMAGE "$IMAGE_URI" '
.taskDefinition
| .containerDefinitions[0].image = $IMAGE
| del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)
' > task-def.json

NEW_TASK_ARN=$(aws ecs register-task-definition \
  --cli-input-json file://task-def.json \
  --query "taskDefinition.taskDefinitionArn" \
  --output text \
  --region "$AWS_REGION")

echo "TASK_DEF_ARN=$NEW_TASK_ARN" >> $GITHUB_ENV