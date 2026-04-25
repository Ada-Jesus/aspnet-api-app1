#!/usr/bin/env bash
set -euo pipefail

: "${ALB_LISTENER_ARN:?Missing ALB_LISTENER_ARN}"
: "${DEPLOY_TG_ARN:?Missing DEPLOY_TG_ARN}"
: "${AWS_REGION:?Missing AWS_REGION}"

echo "==> Switching traffic"

aws elbv2 modify-listener \
  --listener-arn "$ALB_LISTENER_ARN" \
  --default-actions "Type=forward,TargetGroupArn=$DEPLOY_TG_ARN" \
  --region "$AWS_REGION"

echo "Traffic switched"