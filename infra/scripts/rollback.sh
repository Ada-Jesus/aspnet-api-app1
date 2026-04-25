#!/usr/bin/env bash
set -euo pipefail

: "${ECS_CLUSTER:?Missing ECS_CLUSTER}"
: "${ALB_LISTENER_ARN:?Missing ALB_LISTENER_ARN}"
: "${BLUE_SERVICE:?Missing BLUE_SERVICE}"
: "${GREEN_SERVICE:?Missing GREEN_SERVICE}"
: "${BLUE_TG_ARN:?Missing BLUE_TG_ARN}"
: "${GREEN_TG_ARN:?Missing GREEN_TG_ARN}"
: "${DESIRED_COUNT:?Missing DESIRED_COUNT}"
: "${AWS_REGION:?Missing AWS_REGION}"

echo "==> ROLLBACK STARTED"

LIVE_TG=$(aws elbv2 describe-listeners \
  --listener-arns "$ALB_LISTENER_ARN" \
  --query "Listeners[0].DefaultActions[0].TargetGroupArn" \
  --output text \
  --region "$AWS_REGION")

if [ "$LIVE_TG" = "$BLUE_TG_ARN" ]; then
  LIVE_SERVICE="$BLUE_SERVICE"
  PREV_SERVICE="$GREEN_SERVICE"
  PREV_TG="$GREEN_TG_ARN"
else
  LIVE_SERVICE="$GREEN_SERVICE"
  PREV_SERVICE="$BLUE_SERVICE"
  PREV_TG="$BLUE_TG_ARN"
fi

echo "Rolling back to $PREV_SERVICE"

aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$PREV_SERVICE" \
  --desired-count "$DESIRED_COUNT" \
  --region "$AWS_REGION"

aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$PREV_SERVICE" \
  --region "$AWS_REGION"

aws elbv2 modify-listener \
  --listener-arn "$ALB_LISTENER_ARN" \
  --default-actions "Type=forward,TargetGroupArn=$PREV_TG" \
  --region "$AWS_REGION"

aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$LIVE_SERVICE" \
  --desired-count 0 \
  --region "$AWS_REGION"

echo "ROLLBACK COMPLETE"