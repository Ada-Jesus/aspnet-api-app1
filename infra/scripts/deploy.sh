#!/usr/bin/env bash
set -euo pipefail

: "${ECS_CLUSTER:?Missing ECS_CLUSTER}"
: "${DEPLOY_SERVICE:?Missing DEPLOY_SERVICE}"
: "${TASK_DEF_ARN:?Missing TASK_DEF_ARN}"
: "${AWS_REGION:?Missing AWS_REGION}"

echo "==> Deploying to $DEPLOY_SERVICE"

aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$DEPLOY_SERVICE" \
  --task-definition "$TASK_DEF_ARN" \
  --force-new-deployment \
  --region "$AWS_REGION"

aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$DEPLOY_SERVICE"

echo "==> Deployment stable"