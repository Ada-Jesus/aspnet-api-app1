#!/usr/bin/env bash
set -euo pipefail

: "${ALB_DNS_NAME:?Missing}"

URL="http://$ALB_DNS_NAME/health"

for i in {1..10}; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || echo "000")

  if [ "$CODE" = "200" ]; then
    echo "Healthy"
    exit 0
  fi

  echo "Attempt $i failed: $CODE"
  sleep 5
done

echo "Service unhealthy"
exit 1