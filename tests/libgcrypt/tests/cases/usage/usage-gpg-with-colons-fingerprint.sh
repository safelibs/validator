#!/usr/bin/env bash
# @testcase: usage-gpg-with-colons-fingerprint
# @title: gpg with-colons fingerprint
# @description: Lists a generated key with with-colons mode and verifies the machine-readable fingerprint format.
# @timeout: 180
# @tags: usage, crypto, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-with-colons-fingerprint"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator More <validator-more@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_signing_key
gpg --with-colons --fingerprint "$uid" >"$tmpdir/out"
awk -F: '$1 == "fpr" {print $10; exit}' "$tmpdir/out" >"$tmpdir/fpr"
grep -Eq '^[0-9A-F]{40}$' "$tmpdir/fpr"
