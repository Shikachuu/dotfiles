#!/usr/bin/env bash
# List a provider's resources/datasources, or fetch one doc as markdown.
set -euo pipefail
for c in curl jq; do command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }; done
[ $# -ge 1 ] || { echo "usage: $0 <namespace/name> [resource] [version] [--kind resource|datasource|function|guide]" >&2; exit 2; }

API=${TOFU_API:-https://api.opentofu.org}
prov=$1; res=${2:-}; ver=${3:-}; kind=resource
[ "${4:-}" = "--kind" ] && kind=${5:-resource}

if [ -z "$ver" ]; then
  ver=$(curl -fsSL "$API/registry/docs/providers/$prov/index.json" | jq -r '.versions[0].id')
fi

if [ -z "$res" ]; then
  curl -fsSL "$API/registry/docs/providers/$prov/$ver/index.json" | jq -r '
    (.docs.resources[]?   | "resource\t\(.name)\t\(.title)"),
    (.docs.datasources[]? | "datasource\t\(.name)\t\(.title)")'
else
  # Strip a leading "<providername>_" if present -> doc name (aws_instance -> instance).
  doc=${res#*_}
  curl -fsSL "$API/registry/docs/providers/$prov/$ver/${kind}s/$doc.md"
fi
