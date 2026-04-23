#!/usr/bin/env bash
set -euo pipefail

: "${ALB_NAME:?Missing ALB_NAME}"
: "${AWS_REGION:?Missing AWS_REGION}"

echo "==> Monitoring 5XX errors..."

ERRORS=$(aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --start-time "$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --period 300 \
  --statistics Sum \
  --dimensions Name=LoadBalancer,Value="$ALB_NAME" \
  --query 'Datapoints[0].Sum' \
  --output text \
  --region "$AWS_REGION" || echo "0")

ERRORS=${ERRORS:-0}

if [ "$ERRORS" -gt 10 ]; then
  echo "HIGH ERROR RATE: $ERRORS"
  exit 1
fi

echo "OK"