#!/usr/bin/env bash
# @testcase: usage-gpg-hidden-recipient-encrypt-batch11
# @title: gpg hidden recipient encrypt
# @description: Encrypts to a generated hidden recipient and decrypts the message.
# @timeout: 240
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-hidden-recipient-encrypt-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator Batch11 <validator-batch11@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

make_encryption_key
printf 'hidden recipient payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --trust-model always --hidden-recipient "$uid" --encrypt -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
validator_assert_contains "$tmpdir/out" 'hidden recipient payload'
