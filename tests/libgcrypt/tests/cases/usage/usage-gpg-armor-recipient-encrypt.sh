#!/usr/bin/env bash
# @testcase: usage-gpg-armor-recipient-encrypt
# @title: gpg armored recipient encryption
# @description: Encrypts to a generated recipient with ASCII armor and decrypts the message.
# @timeout: 180
# @tags: usage, crypto, encryption
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-armor-recipient-encrypt"
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

make_encryption_key
printf 'armored recipient payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --armor --trust-model always --encrypt -r "$uid" -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
"${gpg_batch[@]}" --decrypt -o "$tmpdir/out" "$tmpdir/plain.asc"
validator_assert_contains "$tmpdir/out" 'armored recipient payload'
