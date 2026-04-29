#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-stdin
# @title: gpg symmetric stdin
# @description: Encrypts stdin through gpg symmetric mode and verifies decrypted output matches the original streamed payload.
# @timeout: 180
# @tags: usage, crypto, encryption
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-stdin"
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

printf 'stdin payload\n' | "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric -o "$tmpdir/stdin.gpg"
"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out.txt" "$tmpdir/stdin.gpg"
validator_assert_contains "$tmpdir/out.txt" 'stdin payload'
