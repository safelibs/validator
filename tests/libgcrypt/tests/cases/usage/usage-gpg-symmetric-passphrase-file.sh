#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-passphrase-file
# @title: gpg symmetric passphrase file
# @description: Encrypts and decrypts with gpg symmetric mode using a passphrase file and verifies the plaintext round-trips.
# @timeout: 180
# @tags: usage, crypto, encryption
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-passphrase-file"
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

printf '%s\n' "$passphrase" >"$tmpdir/passphrase.txt"
printf 'passphrase file payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase-file "$tmpdir/passphrase.txt" --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase-file "$tmpdir/passphrase.txt" --decrypt -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
validator_assert_contains "$tmpdir/out.txt" 'passphrase file payload'
