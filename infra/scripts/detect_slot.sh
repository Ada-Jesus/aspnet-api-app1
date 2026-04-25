#!/usr/bin/env bash
set -euo pipefail

: "${BLUE_TG_ARN:?Missing}"
: "${GREEN_TG_ARN:?Missing}"
: "${BLUE_SERVICE:?Missing}"
: "${GREEN_SERVICE:?Missing}"
: "${ALB_LISTENER_ARN:?Missing}"

LIVE_TG=$(aws elbv2 describe-listeners \
  --listener-arns "$ALB_LISTENER_ARN" \
  --query "Listeners[0].DefaultActions[0].TargetGroupArn" \
  --output text)

if [ "$LIVE_TG" = "$BLUE_TG_ARN" ]; then
  echo "deploy_service=$GREEN_SERVICE" >> $GITHUB_OUTPUT
  echo "deploy_tg=$GREEN_TG_ARN" >> $GITHUB_OUTPUT
else
  echo "deploy_service=$BLUE_SERVICE" >> $GITHUB_OUTPUT
  echo "deploy_tg=$BLUE_TG_ARN" >> $GITHUB_OUTPUT
fi