#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  detect_slot.sh  –  Determine which ECS slot (blue/green) is live
#
#  Required env vars:
#    ALB_LISTENER_ARN, BLUE_TG_ARN, GREEN_TG_ARN
#    BLUE_SERVICE, GREEN_SERVICE, AWS_REGION
#    GITHUB_OUTPUT
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# ================= SAFETY CHECKS =================
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
  --query 'Listeners[0].DefaultActions[0].TargetGroupArn' \
  --output text \
  --region "$AWS_REGION")

if [ "$LIVE_TG" = "$BLUE_TG_ARN" ]; then
  echo "Live = BLUE"
  DEPLOY_SERVICE="$GREEN_SERVICE"
  DEPLOY_TG="$GREEN_TG_ARN"
else
  echo "Live = GREEN"
  DEPLOY_SERVICE="$BLUE_SERVICE"
  DEPLOY_TG="$BLUE_TG_ARN"
fi

echo "deploy_service=$DEPLOY_SERVICE" >> $GITHUB_OUTPUT
echo "deploy_tg=$DEPLOY_TG" >> $GITHUB_OUTPUT
