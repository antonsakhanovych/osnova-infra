#!/usr/bin/env bash
set -euo pipefail

# seed-openbao-secret.sh <kv-path> <username>
#
# Idempotently seeds a username/password pair into OpenBao's KV store,
# so ExternalSecret pulls (from any namespace) have something real to
# read. Generates a random password only if the path doesn't already
# exist - safe to re-run without rotating existing credentials.
#
# Requires: OPENBAO_ROOT_TOKEN set in the environment (or any token with
# write access to secret/*). Never hardcode it, never commit it.
#
# Prerequisite: OpenBao must already be unsealed and configured
# (see configure-openbao.sh) before this will work.
#
# Example: ./seed-openbao-secret.sh keycloak-db keycloak

: "${OPENBAO_ROOT_TOKEN:?Set OPENBAO_ROOT_TOKEN before running this script}"

KV_PATH="${1:?usage: $0 <kv-path> <username>}"
USERNAME="${2:?usage: $0 <kv-path> <username>}"
POD="openbao-0"
NS="openbao"

echo "==> Checking if secret/${KV_PATH} already exists..."
if kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" bao kv get -format=json "secret/${KV_PATH}" >/dev/null 2>&1; then
  echo "    already exists, leaving untouched (delete it first if you want to rotate)"
  exit 0
fi

echo "==> Generating password and writing to secret/${KV_PATH}..."
PASSWORD=$(openssl rand -base64 24)
kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" bao kv put "secret/${KV_PATH}" \
  username="$USERNAME" \
  password="$PASSWORD"

echo "==> Done. secret/${KV_PATH} seeded for username '${USERNAME}'."
