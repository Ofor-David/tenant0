#!/usr/bin/env bash
# Applies the shared (non-per-tenant) serving-path platform manifests.
# No envsubst needed here, unlike universe/apply.sh - nothing in this tier
# is tenant-specific.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f edge-router.yaml
