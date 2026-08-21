#!/usr/bin/env bash
set -euo pipefail

# seed-backup-credentials.sh
#
# Interactively prompts for S3-compatible object store credentials used
# for scheduled database backups (CNPG barman-cloud plugin), and writes
# them into OpenBao. Deliberately provider-agnostic: the same secret
# works whether the values come from Cloudflare R2, Backblaze B2, AWS
# S3, or any other S3-compatible provider - only the ObjectStore
# manifest's endpointURL/destinationPath (plain config, not secret,
# committed to git) need to change if you ever switch providers.
#
# Requires: OPENBAO_ROOT_TOKEN set in the environment. Never hardcode it,
# never commit it.
#
# Prerequisite: OpenBao must already be unsealed and configured
# (see configure-openbao.sh) before this will work.

: "${OPENBAO_ROOT_TOKEN:?Set OPENBAO_ROOT_TOKEN before running this script}"

POD="openbao-0"
NS="openbao"
KV_PATH="db-backup-object-store"

echo "Seeding secret/${KV_PATH} - used by the CNPG barman-cloud ObjectStore."
read -rp "Access Key ID: " ACCESS_KEY_ID
read -rsp "Secret Access Key: " SECRET_ACCESS_KEY
echo

kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" \
  bao kv put "secret/${KV_PATH}" \
  access_key_id="$ACCESS_KEY_ID" \
  secret_access_key="$SECRET_ACCESS_KEY"

echo "==> Done. secret/${KV_PATH} seeded."
