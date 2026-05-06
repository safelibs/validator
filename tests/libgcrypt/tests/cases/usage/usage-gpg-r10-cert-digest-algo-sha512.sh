#!/usr/bin/env bash
# @testcase: usage-gpg-r10-cert-digest-algo-sha512
# @title: gpg --cert-digest-algo SHA512 stamps key self-signature
# @description: Generates an Ed25519 key with --cert-digest-algo SHA512, exports the public key, and verifies gpg --list-packets reports digest algo 10 (SHA512) on the user-id self-signature packet.
# @timeout: 240
# @tags: usage, gpg, certification, digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R10 CertDigest <r10-cert@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --cert-digest-algo SHA512 \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

gpg --batch --export "$uid" >"$tmpdir/pub.gpg" 2>/dev/null
gpg --batch --list-packets "$tmpdir/pub.gpg" >"$tmpdir/packets" 2>&1

# digest algo 10 == SHA512 (RFC 4880 §9.4)
grep -qE 'digest algo 10' "$tmpdir/packets" || {
  printf 'expected digest algo 10 (SHA512) in packets\n' >&2
  sed -n '1,80p' "$tmpdir/packets" >&2
  exit 1
}
