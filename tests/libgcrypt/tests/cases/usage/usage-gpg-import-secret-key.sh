#!/usr/bin/env bash
# @testcase: usage-gpg-import-secret-key
# @title: gpg imports secret key
# @description: Exports a generated secret key and imports it into a second keyring, then verifies the secret key is listed.
# @timeout: 180
# @tags: usage, crypto, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-import-secret-key"
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
"${gpg_batch[@]}" --armor --export-secret-keys "$uid" >"$tmpdir/secret.asc"
other_home="$tmpdir/other"
mkdir -p "$other_home"
chmod 700 "$other_home"
GNUPGHOME="$other_home" gpg --batch --import "$tmpdir/secret.asc" >"$tmpdir/import.out" 2>&1
GNUPGHOME="$other_home" gpg --list-secret-keys "$uid" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'sec'
validator_assert_contains "$tmpdir/out" 'Validator More'
