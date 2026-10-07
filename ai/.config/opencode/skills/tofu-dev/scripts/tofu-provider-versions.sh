#!/usr/bin/env bash
# List a provider's versions (newest first) from the OpenTofu Registry API.
set -euo pipefail
for c in curl jq; do command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }; done
[ $# -eq 1 ] || { echo "usage: $0 <namespace/name>  e.g. hashicorp/aws" >&2; exit 2; }

API=${TOFU_API:-https://api.opentofu.org}
prov=$1
curl -fsSL "$API/registry/docs/providers/$prov/index.json" \
  | jq -r '.versions[] | "\(.id)\t\(.published)"'
