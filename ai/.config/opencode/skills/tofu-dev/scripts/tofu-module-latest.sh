#!/usr/bin/env bash
# Latest version + suggested pessimistic pin for a registry module.
set -euo pipefail
for c in curl jq; do command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }; done
[ $# -eq 1 ] || { echo "usage: $0 <namespace/name/target>  e.g. terraform-aws-modules/vpc/aws" >&2; exit 2; }

API=${TOFU_API:-https://api.opentofu.org}
mod=$1
latest=$(curl -fsSL "$API/registry/docs/modules/$mod/index.json" | jq -r '.versions[0].id')
ver=${latest#v}       # strip leading v
major=${ver%%.*}      # first segment -> major
echo "latest: $latest"
echo "pin:    ~> ${major}.0"
