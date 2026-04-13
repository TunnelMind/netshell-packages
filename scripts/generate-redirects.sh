#!/usr/bin/env bash
# Writes _redirects pointing package downloads to the GitHub Release.
# Usage: ./scripts/generate-redirects.sh v1.0.0
set -euo pipefail

VERSION=${1:-v1.0.0}
VER=${VERSION#v}
BASE="https://github.com/TunnelMind/netshell/releases/download/${VERSION}"

cat > _redirects << EOF
/apt/pool/main/n/netshell/netshell_${VER}_amd64.deb  ${BASE}/netshell_${VER}_amd64.deb  302
/rpm/stable/x86_64/netshell-${VER}-1.x86_64.rpm       ${BASE}/netshell-${VER}-1.x86_64.rpm  302
EOF

echo "_redirects written for $VERSION"
