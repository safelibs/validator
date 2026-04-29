#!/usr/bin/env bash
# @testcase: usage-gpg-export-import-key
# @title: GnuPG exports and imports key
# @description: Exports a generated public key and imports it into a fresh keyring.
# @timeout: 180
# @tags: usage, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-export-import-key"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator User <validator@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

make_signing_key
gpg --armor --export "$uid" >"$tmpdir/pub.asc"
export GNUPGHOME="$tmpdir/imported"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg --batch --import "$tmpdir/pub.asc" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'imported'
