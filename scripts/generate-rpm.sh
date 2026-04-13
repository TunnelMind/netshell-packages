#!/usr/bin/env bash
# Regenerates RPM repo metadata for a given version.
# Usage: ./scripts/generate-rpm.sh v1.0.0
set -euo pipefail

VERSION=${1:-v1.0.0}
VER=${VERSION#v}
RPM_FILE="packages/netshell-${VER}-1.x86_64.rpm"

if [[ ! -f "$RPM_FILE" ]]; then
  echo "ERROR: $RPM_FILE not found. Download it first."
  exit 1
fi

mkdir -p rpm/stable/x86_64

# Copy RPM into repo dir for createrepo to index, then remove after
cp "$RPM_FILE" rpm/stable/x86_64/
createrepo_c rpm/stable/x86_64/
rm rpm/stable/x86_64/netshell-*.rpm

# Sign repomd.xml
GPG_FPR=$(gpg --list-keys --with-colons packages@tunnelmind.ai | awk -F: '/^fpr/{print $10; exit}')
gpg --batch --no-tty --pinentry-mode loopback --default-key "$GPG_FPR" \
  --detach-sign --armor rpm/stable/x86_64/repodata/repomd.xml

echo "RPM repo updated for $VERSION"
