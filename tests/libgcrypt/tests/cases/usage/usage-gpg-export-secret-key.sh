#!/usr/bin/env bash
# @testcase: usage-gpg-export-secret-key
# @title: gpg exports secret key
# @description: Exports a generated secret key in armor form and checks the block header.
# @timeout: 180
# @tags: usage, crypto, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-export-secret-key"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator Extra <validator-extra@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

make_signing_key
"${gpg_batch[@]}" --armor --export-secret-keys "$uid" >"$tmpdir/secret.asc"
validator_assert_contains "$tmpdir/secret.asc" 'BEGIN PGP PRIVATE KEY BLOCK'
