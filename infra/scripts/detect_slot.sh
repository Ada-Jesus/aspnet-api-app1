#!/usr/bin/env bash
set -euo pipefail

: "${ALB_LISTENER_ARN:?Missing ALB_LISTENER_ARN}"
: "${BLUE_TG_ARN:?Missing BLUE_TG_ARN}"
: "${GREEN_TG_ARN:?Missing GREEN_TG_ARN}"
: "${BLUE_SERVICE:?Missing BLUE_SERVICE}"
: "${GREEN_SERVICE:?Missing GREEN_SERVICE}"
: "${AWS_REGION:?Missing AWS_REGION}"

echo "==> Detecting active slot..."

LIVE_TG=$(aws elbv2 describe-listeners \
  --listener-arns "$ALB_LISTENER_ARN" \
  --query "Listeners[0].DefaultActions[0].TargetGroupArn" \
  --output text \
  --region "$AWS_REGION")

if [ "$LIVE_TG" = "$BLUE_TG_ARN" ]; then
  DEPLOY_SERVICE="$GREEN_SERVICE"
  DEPLOY_TG="$GREEN_TG_ARN"
  LIVE_SERVICE="$BLUE_SERVICE"
else
  DEPLOY_SERVICE="$BLUE_SERVICE"
  DEPLOY_TG="$BLUE_TG_ARN"
  LIVE_SERVICE="$GREEN_SERVICE"
fi

{
  echo "deploy_service=$DEPLOY_SERVICE"
  echo "deploy_tg=$DEPLOY_TG"
  echo "live_service=$LIVE_SERVICE"
  echo "live_tg=$LIVE_TG"
} >> "$GITHUB_OUTPUT"