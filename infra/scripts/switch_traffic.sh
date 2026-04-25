#!/usr/bin/env bash
set -euo pipefail

: "${ALB_LISTENER_ARN:?Missing}"
: "${DEPLOY_TG_ARN:?Missing}"
: "${AWS_REGION:?Missing}"

aws elbv2 modify-listener \
  --listener-arn "$ALB_LISTENER_ARN" \
  --default-actions "Type=forward,TargetGroupArn=$DEPLOY_TG_ARN" \
  --region "$AWS_REGION"