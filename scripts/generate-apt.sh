#!/usr/bin/env bash
# Regenerates APT repo metadata for a given version.
# Usage: ./scripts/generate-apt.sh v1.0.0
set -euo pipefail

VERSION=${1:-v1.0.0}
VER=${VERSION#v}
DEB="packages/netshell_${VER}_amd64.deb"

if [[ ! -f "$DEB" ]]; then
  echo "ERROR: $DEB not found. Download it first."
  exit 1
fi

mkdir -p apt/dists/stable/main/binary-amd64 apt/pool/main/n/netshell

# Extract control fields
PKG_NAME=$(dpkg-deb -f "$DEB" Package)
PKG_VER=$(dpkg-deb -f "$DEB" Version)
PKG_ARCH=$(dpkg-deb -f "$DEB" Architecture)
PKG_INST=$(dpkg-deb -f "$DEB" Installed-Size)
PKG_DEPS=$(dpkg-deb -f "$DEB" Depends)
PKG_RECO=$(dpkg-deb -f "$DEB" Recommends || true)
PKG_SUGG=$(dpkg-deb -f "$DEB" Suggests || true)

SHA256=$(sha256sum "$DEB" | awk '{print $1}')
SHA1=$(sha1sum "$DEB" | awk '{print $1}')
MD5=$(md5sum "$DEB" | awk '{print $1}')
SIZE=$(stat -c%s "$DEB")

cat > apt/dists/stable/main/binary-amd64/Packages << EOF
Package: $PKG_NAME
Version: $PKG_VER
Architecture: $PKG_ARCH
Maintainer: NetShell
Installed-Size: $PKG_INST
Depends: $PKG_DEPS
Recommends: $PKG_RECO
Suggests: $PKG_SUGG
Section: utils
Priority: optional
Homepage: https://tunnelmind.ai/products
Filename: pool/main/n/netshell/netshell_${VER}_amd64.deb
Size: $SIZE
SHA256: $SHA256
SHA1: $SHA1
MD5sum: $MD5
Description: SSH/Telnet/Serial terminal for network engineers
 Multi-tab sessions, encrypted credential vault, broadcast commands to multiple
 devices simultaneously, compliance scanning (CIS/STIG), AI-assisted
 troubleshooting, topology discovery via LLDP, TFTP file transfer, GitOps
 config drift detection, and session recording with Ed25519 audit signatures.
 Connects to SSH, Telnet, Serial, Cisco Meraki, gNMI, Kubernetes, and AWS SSM.
EOF

gzip -k -9 -f apt/dists/stable/main/binary-amd64/Packages

PKGS_SHA256=$(sha256sum apt/dists/stable/main/binary-amd64/Packages | awk '{print $1}')
PKGS_SIZE=$(stat -c%s apt/dists/stable/main/binary-amd64/Packages)
PKGS_GZ_SHA256=$(sha256sum apt/dists/stable/main/binary-amd64/Packages.gz | awk '{print $1}')
PKGS_GZ_SIZE=$(stat -c%s apt/dists/stable/main/binary-amd64/Packages.gz)
NOW=$(date -u "+%a, %d %b %Y %H:%M:%S UTC")

cat > apt/dists/stable/Release << EOF
Origin: NetShell
Label: NetShell
Suite: stable
Codename: stable
Version: $VER
Architectures: amd64
Components: main
Description: NetShell package repository
Date: $NOW
SHA256:
 $PKGS_SHA256 $PKGS_SIZE main/binary-amd64/Packages
 $PKGS_GZ_SHA256 $PKGS_GZ_SIZE main/binary-amd64/Packages.gz
EOF

GPG_FPR=$(gpg --list-keys --with-colons packages@tunnelmind.ai | awk -F: '/^fpr/{print $10; exit}')
GPG_OPTS="--batch --no-tty --pinentry-mode loopback --default-key $GPG_FPR"
# shellcheck disable=SC2086
gpg $GPG_OPTS --clearsign --armor \
  --output apt/dists/stable/InRelease apt/dists/stable/Release
# shellcheck disable=SC2086
gpg $GPG_OPTS --detach-sign --armor \
  --output apt/dists/stable/Release.gpg apt/dists/stable/Release

echo "APT repo updated for $VERSION"
