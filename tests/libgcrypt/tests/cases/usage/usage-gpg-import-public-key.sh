#!/usr/bin/env bash
# @testcase: usage-gpg-import-public-key
# @title: gpg imports public key
# @description: Imports an exported public key into a second GNUPGHOME and verifies key listing output.
# @timeout: 180
# @tags: usage, crypto, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-import-public-key"
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
"${gpg_batch[@]}" --armor --export "$uid" >"$tmpdir/public.asc"
other_home="$tmpdir/other"
mkdir -p "$other_home"
chmod 700 "$other_home"
GNUPGHOME="$other_home" gpg --batch --import "$tmpdir/public.asc" >"$tmpdir/out" 2>&1
GNUPGHOME="$other_home" gpg --list-keys "$uid" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'Validator Extra'
