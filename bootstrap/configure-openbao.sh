#!/usr/bin/env bash
set -euo pipefail

# configure-openbao.sh
#
# One-time (but safe to re-run) configuration of OpenBao after unseal:
# enables the KV secrets engine, creates the ESO read policy, and wires
# up Kubernetes auth so ExternalSecrets Operator can authenticate without
# any static token.
#
# Requires: OPENBAO_ROOT_TOKEN set in the environment. Never hardcode it,
# never commit it. Run once per fresh OpenBao instance.

: "${OPENBAO_ROOT_TOKEN:?Set OPENBAO_ROOT_TOKEN before running this script}"

POD="openbao-0"
NS="openbao"

echo "==> Logging in..."
kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" bao token lookup >/dev/null

echo "==> Ensuring KV v2 secrets engine is enabled at secret/..."
if ! kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" bao secrets list -format=json | grep -q '"secret/"'; then
  kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" bao secrets enable -path=secret kv-v2
else
  echo "    already enabled, skipping"
fi

echo "==> Writing eso-reader policy..."
kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" bao policy write eso-reader - <<'EOF'
path "secret/data/*" {
  capabilities = ["read"]
}
EOF

echo "==> Ensuring Kubernetes auth method is enabled..."
if ! kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" bao auth list -format=json | grep -q '"kubernetes/"'; then
  kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" bao auth enable kubernetes
else
  echo "    already enabled, skipping"
fi

echo "==> Configuring Kubernetes auth..."
kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" bao write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443"

echo "==> Writing eso role..."
kubectl exec -i "$POD" -n "$NS" -- env BAO_TOKEN="$OPENBAO_ROOT_TOKEN" bao write auth/kubernetes/role/eso \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=eso-reader \
  ttl=1h

echo "==> Done. OpenBao configured for ESO access."
