#!/usr/bin/env bash
set -euo pipefail

# install-local-path-provisioner.sh
#
# Assumes Talos is already applied/bootstrapped and TALOSCONFIG/kubeconfig
# are working (that part stays manual - see README). This script handles
# everything after "kubectl get nodes shows Ready":
#   - local-path-provisioner (storage), installed via Helm, pinned version
#   - Pod Security namespace label (kubectl — not something a chart owns)
#   - sets local-path as the default StorageClass (via chart values)
#
# Safe to re-run.

LOCAL_PATH_PROVISIONER_VERSION="v0.0.36"
CHART_DIR="$(mktemp -d)"

echo "==> Fetching local-path-provisioner chart (pinned ${LOCAL_PATH_PROVISIONER_VERSION})..."
git clone --depth 1 --branch "${LOCAL_PATH_PROVISIONER_VERSION}" \
  https://github.com/rancher/local-path-provisioner.git "${CHART_DIR}"

echo "==> Ensuring local-path-storage namespace exists with correct Pod Security label..."
kubectl apply -f infra/local-path-provisioner/namespace.yaml

echo "==> Installing/upgrading local-path-provisioner via Helm..."
helm upgrade --install local-path-provisioner \
  "${CHART_DIR}/deploy/chart/local-path-provisioner" \
  --namespace local-path-storage \
  --set storageClass.defaultClass=true

echo "==> Waiting for provisioner to be ready..."
kubectl wait --for=condition=available --timeout=120s \
  -n local-path-storage deployment/local-path-provisioner

echo "==> Cleaning up temp chart checkout..."
rm -rf "${CHART_DIR}"

echo "==> Done. Storage classes:"
kubectl get storageclass
