#!/usr/bin/env bash
set -euo pipefail

# seed-secret.sh <kv-path> <key> [<key> ...]
#
# Interactively prompts for one or more externally-generated secret values
# (API tokens, access keys, etc.) and writes them into OpenBao under
# secret/<kv-path>, one field per <key>. Generic replacement for writing a
# new one-off script per credential - prompted rather than taken as CLI
# args, so values never land in shell history.
#
# For generating a random password instead of prompting for an external
# one, use seed-openbao-secret.sh.
#
# Requires: OPENBAO_ROOT_TOKEN set in the environment. Never hardcode it,
# never commit it.
#
# Prerequisite: OpenBao must already be unsealed and configured
# (see configure-openbao.sh) before this will work.
#
# Examples:
#   ./seed-secret.sh db-backup-object-store access_key_id secret_access_key
#   ./seed-secret.sh cloudflare-dns-token api_token

: "${OPENBAO_ROOT_TOKEN:?Set OPENBAO_ROOT_TOKEN before running this script}"

KV_PATH="${1:?usage: $0 <kv-path> <key> [<key> ...]}"
shift
if [ "$#" -eq 0 ]; then
  echo "usage: $0 <kv-path> <key> [<key> ...]" >&2
  exit 1
fi

POD="openbao-0"
NS="openbao"

echo "Seeding secret/${KV_PATH}..."

KV_ARGS=()
for KEY in "$@"; do
  read -rsp "${KEY}: " VALUE
  echo
  KV_ARGS+=("${KEY}=${VALUE}")
done

kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" \
  bao kv put "secret/${KV_PATH}" "${KV_ARGS[@]}"

echo "==> Done. secret/${KV_PATH} seeded."
