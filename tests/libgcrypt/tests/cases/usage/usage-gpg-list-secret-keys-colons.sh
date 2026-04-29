#!/usr/bin/env bash
# @testcase: usage-gpg-list-secret-keys-colons
# @title: gpg list secret keys with colons
# @description: Lists secret keys in machine-readable format with gpg and verifies secret-key and fingerprint records are present.
# @timeout: 180
# @tags: usage, crypto, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-secret-keys-colons"
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
gpg --with-colons --list-secret-keys "$uid" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'sec'
validator_assert_contains "$tmpdir/out" 'fpr'
