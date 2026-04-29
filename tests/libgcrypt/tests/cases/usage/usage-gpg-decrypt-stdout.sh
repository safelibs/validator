#!/usr/bin/env bash
# @testcase: usage-gpg-decrypt-stdout
# @title: gpg decrypts to stdout
# @description: Decrypts a symmetric gpg message directly to stdout and verifies the recovered plaintext stream.
# @timeout: 180
# @tags: usage, crypto, encryption
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-decrypt-stdout"
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

printf 'stdout decrypt payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt "$tmpdir/plain.gpg" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'stdout decrypt payload'
