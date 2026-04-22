#!/usr/bin/env bash
set -euo pipefail

echo "==> Fetching task definition for: ${DEPLOY_SERVICE}"

CURRENT_TD=$(aws ecs describe-services \
  --cluster "${ECS_CLUSTER}" \
  --services "${DEPLOY_SERVICE}" \
  --query 'services[0].taskDefinition' \
  --output text \
  --region "${AWS_REGION}")

echo "    Current TD: ${CURRENT_TD}"
echo "    New image:  ${IMAGE_URI}"

NEW_TD=$(aws ecs describe-task-definition \
  --task-definition "${CURRENT_TD}" \
  --query 'taskDefinition' \
  --output json \
  --region "${AWS_REGION}" | \
  jq --arg IMAGE "${IMAGE_URI}" '
    del(
      .taskDefinitionArn,
      .revision,
      .status,
      .requiresAttributes,
      .placementConstraints,
      .compatibilities,
      .registeredAt,
      .registeredBy
    )
    | .containerDefinitions[0].image = $IMAGE
  ' | \
  aws ecs register-task-definition \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text \
    --region "${AWS_REGION}")

echo "task_def_arn=${NEW_TD}" >> "$GITHUB_OUTPUT"

echo "==> Task registered: ${NEW_TD}"
