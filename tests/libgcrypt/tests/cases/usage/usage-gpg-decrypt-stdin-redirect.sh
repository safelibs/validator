#!/usr/bin/env bash
# @testcase: usage-gpg-decrypt-stdin-redirect
# @title: gpg --decrypt reads ciphertext via stdin redirection
# @description: Encrypts a payload symmetrically, then decrypts it by feeding the OpenPGP message to gpg over stdin (no file argument) and verifies the recovered plaintext.
# @timeout: 180
# @tags: usage, gpg, encryption, stdin
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-decrypt-stdin-redirect"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase

printf 'stdin redirect payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase "$passphrase" --symmetric --cipher-algo AES256 \
  -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

# Decrypt by redirecting the file onto stdin; no positional input argument.
"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt <"$tmpdir/cipher.gpg" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'stdin redirect payload'
