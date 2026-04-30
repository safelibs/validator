#!/usr/bin/env bash
# @testcase: usage-gpg-encrypt-output-dash-stdout
# @title: gpg --output - writes encrypted message to stdout
# @description: Encrypts a payload symmetrically with --output - so the OpenPGP message is delivered on stdout, then decrypts the captured stream and verifies the recovered plaintext.
# @timeout: 180
# @tags: usage, gpg, encryption, stdout
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-encrypt-output-dash-stdout"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase

printf 'output-dash payload\n' >"$tmpdir/plain.txt"

# --output - must direct the encrypted OpenPGP message to stdout; capture it.
"${gpg_batch[@]}" --passphrase "$passphrase" --symmetric --cipher-algo AES256 \
  --output - "$tmpdir/plain.txt" >"$tmpdir/cipher.gpg"

# Sanity: file must be non-empty and not equal to plaintext.
[[ -s "$tmpdir/cipher.gpg" ]] || { echo "stdout cipher empty" >&2; exit 1; }
! cmp -s "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

# Round-trip decrypt and assert plaintext recovered.
"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out.txt" "$tmpdir/cipher.gpg"
validator_assert_contains "$tmpdir/out.txt" 'output-dash payload'
