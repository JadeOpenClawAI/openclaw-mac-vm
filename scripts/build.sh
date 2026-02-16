#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./build.sh bluebubbles
#   ./build.sh openclaw
#   ./build.sh bluebubbles tahoe

TEMPLATE="${1:-bluebubbles}"
MACOS_VERSION="${2:-}"

case "$TEMPLATE" in
  bluebubbles|openclaw) ;;
  *) echo "Template must be 'bluebubbles' or 'openclaw'" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/../packer"
packer init .

if [[ -n "$MACOS_VERSION" ]]; then
  packer build -var "macos_version=$MACOS_VERSION" "${TEMPLATE}.pkr.hcl"
else
  packer build "${TEMPLATE}.pkr.hcl"
fi
