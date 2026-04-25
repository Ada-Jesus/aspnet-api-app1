#!/usr/bin/env bash
set -euo pipefail

: "${ECS_CLUSTER:?Missing}"
: "${DEPLOY_SERVICE:?Missing}"
: "${TASK_DEF_ARN:?Missing}"
: "${AWS_REGION:?Missing}"

aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$DEPLOY_SERVICE" \
  --task-definition "$TASK_DEF_ARN" \
  --desired-count 1 \
  --region "$AWS_REGION"

aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$DEPLOY_SERVICE"