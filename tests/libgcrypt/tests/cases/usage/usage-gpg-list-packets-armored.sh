#!/usr/bin/env bash
# @testcase: usage-gpg-list-packets-armored
# @title: gpg list packets armored
# @description: Lists packets from an armored encrypted message with gpg and verifies the symmetric packet summary appears.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-packets-armored"
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

printf 'armored packet payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --armor --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase "$passphrase" --list-packets "$tmpdir/plain.asc" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'literal data packet'
