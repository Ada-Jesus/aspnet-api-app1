#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  validate_and_rollback.sh  –  Post-switch validation + auto-rollback
#
#  Required env vars:
#    ALB_DNS_NAME, ALB_LISTENER_ARN
#    LIVE_TG_ARN
#    LIVE_SERVICE
#    DEPLOY_SERVICE
#    ECS_CLUSTER
#    DESIRED_COUNT
#    AWS_REGION
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

CHECKS="${VALIDATION_CHECKS:-5}"
DELAY="${VALIDATION_DELAY:-5}"
URL="http://${ALB_DNS_NAME}/health"

echo "==> Post-switch validation: ${URL}"

sleep 10

rollback() {
  echo ""
  echo "!!! AUTO-ROLLBACK TRIGGERED !!!"
  bash infra/scripts/rollback.sh
  exit 1
}

trap rollback ERR

for i in $(seq 1 "${CHECKS}"); do
  HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    "${URL}" || echo "000")

  echo "  Check ${i}/${CHECKS}: ${HTTP_CODE}"

  if [ "${HTTP_CODE}" != "200" ]; then
    echo "  FAIL"
    rollback
  fi

  sleep "${DELAY}"
done

trap - ERR

echo "==> Validation passed"