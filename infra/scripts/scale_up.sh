#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  scale_up.sh  –  Update deploy slot with new task def & scale up
#
#  Required env vars:
#    ECS_CLUSTER
#    DEPLOY_SERVICE
#    TASK_DEF_ARN
#    DESIRED_COUNT
#    AWS_REGION
# ═══════════════════════════════════════════════════════════════════
#!/bin/bash
set -euo pipefail

: "${TASK_DEF_ARN:?Missing TASK_DEF_ARN}"
: "${DEPLOY_SERVICE:?Missing DEPLOY_SERVICE}"
: "${ECS_CLUSTER:?Missing ECS_CLUSTER}"
: "${DESIRED_COUNT:?Missing DESIRED_COUNT}"
: "${AWS_REGION:?Missing AWS_REGION}"

echo "==> Scaling up: $DEPLOY_SERVICE"
echo "Using task definition: $TASK_DEF_ARN"

aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$DEPLOY_SERVICE" \
  --task-definition "$TASK_DEF_ARN" \
  --desired-count "$DESIRED_COUNT" \
  --region "$AWS_REGION"

echo "==> Waiting for service to stabilize..."

aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$DEPLOY_SERVICE"

echo "==> Deploy slot stable"
