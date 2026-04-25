#!/usr/bin/env bash
set -euo pipefail

: "${ALB_DNS_NAME:?Missing ALB_DNS_NAME}"

RETRIES="${HEALTH_RETRIES:-10}"
DELAY="${HEALTH_DELAY:-5}"
PATH_CHECK="${HEALTH_PATH:-/health}"

URL="http://${ALB_DNS_NAME}:8080${PATH_CHECK}"

echo "==> Health check: $URL"

for i in $(seq 1 "$RETRIES"); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL" || echo "000")

  if [ "$CODE" = "200" ]; then
    echo "Healthy"
    exit 0
  fi

  echo "Attempt $i: $CODE"
  sleep "$DELAY"
done

echo "FAILED HEALTH CHECK"
exit 1