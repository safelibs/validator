#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-3des
# @title: gpg 3DES symmetric round trip
# @description: Encrypts and decrypts a file with gpg symmetric 3DES mode and verifies the recovered payload.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-3des"
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

printf '3des payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --allow-old-cipher-algos --passphrase "$passphrase" --symmetric --cipher-algo 3DES -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
validator_assert_contains "$tmpdir/out" '3des payload'
