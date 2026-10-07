#!/usr/bin/env bash
# Search the OpenTofu Registry for modules.
set -euo pipefail
for c in curl jq; do command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }; done
[ $# -ge 1 ] || { echo "usage: $0 <query>" >&2; exit 2; }

API=${TOFU_API:-https://api.opentofu.org}
q=$*
enc=$(printf '%s' "$q" | jq -sRr @uri)
curl -fsSL "$API/registry/docs/search?q=$enc" | jq -r '
  .[] | select(.type=="module")
  | "\(.addr)\t\(.version)\t\(.description)"'
