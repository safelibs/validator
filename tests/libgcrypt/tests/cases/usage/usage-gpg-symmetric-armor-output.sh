#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-armor-output
# @title: gpg symmetric armor output
# @description: Produces an ASCII-armored symmetric message through gpg --armor and verifies decryption restores the original body.
# @timeout: 180
# @tags: usage, gpg, armor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-armor-output"
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

printf 'symmetric armor body\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --armor --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.asc"
validator_assert_contains "$tmpdir/out" 'symmetric armor body'
