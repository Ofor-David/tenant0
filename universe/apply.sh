#!/usr/bin/env bash
# Substitutes real values from universe/.env (gitignored) into composition.yaml
# and applies it. Run this instead of `kubectl apply -f composition.yaml`
# directly, that would apply the literal ${VAR} placeholders.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "universe/.env not found, copy .env.example to .env and fill in real values" >&2
  exit 1
fi

set -a
source .env
set +a

envsubst < composition.yaml | kubectl apply -f -
