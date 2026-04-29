#!/usr/bin/env bash
# @testcase: usage-gpg-decrypt-clearsigned-message
# @title: gpg decrypt clearsigned message
# @description: Decrypts a clearsigned message with gpg and verifies the extracted cleartext body.
# @timeout: 180
# @tags: usage, gpg, signature
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-decrypt-clearsigned-message"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator Further <validator-further@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_signing_key
printf 'clear payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --clearsign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
gpg --decrypt "$tmpdir/plain.asc" >"$tmpdir/out" 2>/dev/null
validator_assert_contains "$tmpdir/out" 'clear payload'
