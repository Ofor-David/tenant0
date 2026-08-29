#!/usr/bin/env bash
# Substitutes TENANT0_OPERATOR_EMAIL from ../universe/.env (gitignored) into
# admission-policy.yaml and applies it. Run this instead of `kubectl apply -f
# admission-policy.yaml` directly, that would apply the literal ${VAR}
# placeholder.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f ../universe/.env ]]; then
  echo "universe/.env not found, copy universe/.env.example to universe/.env and fill in real values" >&2
  exit 1
fi

set -a
source ../universe/.env
set +a

envsubst '$TENANT0_OPERATOR_EMAIL' < admission-policy.yaml | kubectl apply -f -
