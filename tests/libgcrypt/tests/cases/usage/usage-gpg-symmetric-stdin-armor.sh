#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-stdin-armor
# @title: gpg symmetric stdin armor
# @description: Encrypts payload from stdin with gpg armored symmetric output and verifies decryption restores the streamed body.
# @timeout: 180
# @tags: usage, gpg, stdin
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-stdin-armor"
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

printf 'stdin armor payload\n' | "${gpg_batch[@]}" --armor --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.asc"
validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.asc"
validator_assert_contains "$tmpdir/out" 'stdin armor payload'
