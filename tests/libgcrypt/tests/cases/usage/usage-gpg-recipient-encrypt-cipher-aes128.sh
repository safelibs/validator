#!/usr/bin/env bash
# @testcase: usage-gpg-recipient-encrypt-cipher-aes128
# @title: gpg recipient encrypt+decrypt with --cipher-algo AES128
# @description: Generates an RSA encryption key and round-trips a public-key encrypted message while pinning the session cipher to AES128 via --cipher-algo, asserting the recovered plaintext matches.
# @timeout: 240
# @tags: usage, gpg, encryption, cipher
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-recipient-encrypt-cipher-aes128"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator AES128Recipient <validator-aes128rcp@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1

printf 'aes128 recipient payload\n' >"$tmpdir/plain.txt"

"${gpg_batch[@]}" --trust-model always --cipher-algo AES128 \
  --encrypt -r "$uid" \
  -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"

# Sanity-check that an OpenPGP message was produced.
test -s "$tmpdir/plain.gpg"

"${gpg_batch[@]}" --decrypt -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
validator_assert_contains "$tmpdir/out.txt" 'aes128 recipient payload'
