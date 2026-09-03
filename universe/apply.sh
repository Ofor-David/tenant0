#!/usr/bin/env bash
# Substitutes real values from universe/.env (gitignored) into every
# XRD/Composition pair and applies them. Run this instead of
# `kubectl apply -f composition.yaml` directly, that would apply the literal
# ${VAR} placeholders.
#
# Order matters: the 5 sub-XRDs (tenant-project, tenant-database,
# tenant-network, tenant-workloads, tenant-secrets) must be Established
# before the top-level Tenant Composition, which composes them, is applied -
# same ordering gotcha documented for provider CRD installs in
# docs/PHASE0_SETUP.md.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "universe/.env not found, copy .env.example to .env and fill in real values" >&2
  exit 1
fi

set -a
source .env
set +a

VARS='$TENANT0_FOLDER_ID $TENANT0_BILLING_ACCOUNT_ID $TENANT0_HOST_NETWORK_PROJECT_NUMBER $TENANT0_OPERATOR_MEMBER'

apply() {
  envsubst "$VARS" < "$1" | kubectl apply -f -
}

for sub in tenant-project tenant-database tenant-network tenant-workloads tenant-secrets; do
  apply "$sub/xrd.yaml"
  apply "$sub/composition.yaml"
done

apply xrd.yaml
apply composition.yaml
