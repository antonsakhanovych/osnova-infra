#!/usr/bin/env bash
set -euo pipefail

# seed-cloudflare-token.sh
#
# Interactively prompts for a Cloudflare API token (scoped to DNS edit on
# the zone cert-manager needs) and writes it into OpenBao, so cert-manager's
# ClusterIssuer can solve ACME DNS-01 challenges. Prompted rather than
# taken as a CLI arg, so it never lands in shell history.
#
# Requires: OPENBAO_ROOT_TOKEN set in the environment. Never hardcode it,
# never commit it.
#
# Prerequisite: OpenBao must already be unsealed and configured
# (see configure-openbao.sh) before this will work.

: "${OPENBAO_ROOT_TOKEN:?Set OPENBAO_ROOT_TOKEN before running this script}"

POD="openbao-0"
NS="openbao"
KV_PATH="cloudflare-dns-token"

echo "Seeding secret/${KV_PATH} - used by cert-manager's ClusterIssuer for DNS-01."
read -rsp "Cloudflare API Token: " API_TOKEN
echo

kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" \
  bao kv put "secret/${KV_PATH}" \
  api_token="$API_TOKEN"

echo "==> Done. secret/${KV_PATH} seeded."
