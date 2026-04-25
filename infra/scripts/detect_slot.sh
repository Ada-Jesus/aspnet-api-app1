#!/usr/bin/env bash
set -euo pipefail

: "${ALB_LISTENER_ARN:?Missing}"
: "${BLUE_TG_ARN:?Missing}"
: "${GREEN_TG_ARN:?Missing}"
: "${BLUE_SERVICE:?Missing}"
: "${GREEN_SERVICE:?Missing}"
: "${AWS_REGION:?Missing}"

LIVE_TG=$(aws elbv2 describe-listeners \
  --listener-arns "$ALB_LISTENER_ARN" \
  --query "Listeners[0].DefaultActions[0].TargetGroupArn" \
  --output text \
  --region "$AWS_REGION")

if [ "$LIVE_TG" = "$BLUE_TG_ARN" ]; then
  LIVE_SERVICE=$BLUE_SERVICE
  DEPLOY_SERVICE=$GREEN_SERVICE
  DEPLOY_TG=$GREEN_TG_ARN
else
  LIVE_SERVICE=$GREEN_SERVICE
  DEPLOY_SERVICE=$BLUE_SERVICE
  DEPLOY_TG=$BLUE_TG_ARN
fi

echo "deploy_service=$DEPLOY_SERVICE" >> $GITHUB_OUTPUT
echo "deploy_tg=$DEPLOY_TG" >> $GITHUB_OUTPUT
echo "live_service=$LIVE_SERVICE" >> $GITHUB_OUTPUT