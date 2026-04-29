#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-aes192
# @title: gpg AES192 symmetric round trip
# @description: Encrypts and decrypts a file with gpg AES192 symmetric encryption.
# @timeout: 180
# @tags: usage, crypto, encryption
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-aes192"
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

printf 'aes192 payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase "$passphrase" --symmetric --cipher-algo AES192 -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
validator_assert_contains "$tmpdir/out" 'aes192 payload'
