# CNPG Barman Cloud plugin

Vendored, not templated — CloudNativePG's backup plugin ships as a plain
manifest, not a Helm chart. `manifest.yaml` is an unmodified copy of:

https://github.com/cloudnative-pg/plugin-barman-cloud/releases/download/v0.14.0/manifest.yaml

Requires cert-manager to already be installed (it self-issues its own
internal mTLS certs via a bundled selfsigned `Issuer`). Must be applied in
the same namespace as the CloudNativePG operator (`cnpg-system`).

To upgrade: download the new release's `manifest.yaml`, replace this file
wholesale, update the version referenced here.
