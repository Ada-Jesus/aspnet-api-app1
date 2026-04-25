#!/usr/bin/env bash
set -euo pipefail

: "${ECS_CLUSTER:?Missing}"
: "${ALB_LISTENER_ARN:?Missing}"
: "${BLUE_SERVICE:?Missing}"
: "${GREEN_SERVICE:?Missing}"
: "${BLUE_TG_ARN:?Missing}"
: "${GREEN_TG_ARN:?Missing}"
: "${DESIRED_COUNT:?Missing}"
: "${AWS_REGION:?Missing}"

LIVE_TG=$(aws elbv2 describe-listeners \
  --listener-arns "$ALB_LISTENER_ARN" \
  --query "Listeners[0].DefaultActions[0].TargetGroupArn" \
  --output text)

if [ "$LIVE_TG" = "$BLUE_TG_ARN" ]; then
  PREV_SERVICE=$GREEN_SERVICE
  PREV_TG=$GREEN_TG_ARN
else
  PREV_SERVICE=$BLUE_SERVICE
  PREV_TG=$BLUE_TG_ARN
fi

aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$PREV_SERVICE" \
  --desired-count "$DESIRED_COUNT"

aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$PREV_SERVICE"

aws elbv2 modify-listener \
  --listener-arn "$ALB_LISTENER_ARN" \
  --default-actions "Type=forward,TargetGroupArn=$PREV_TG"

echo "Rollback complete"