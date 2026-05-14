#!/usr/bin/env bash
# @testcase: usage-gpg-r18-symmetric-encrypt-decrypt-roundtrip
# @title: gpg --symmetric then --decrypt roundtrip yields the original plaintext
# @description: Encrypts a fixed plaintext "round18 symmetric payload" with gpg --symmetric using a known passphrase via --pinentry-mode loopback and AES256, decrypts the resulting ciphertext, and asserts the decrypted bytes match the original byte-for-byte, exercising libgcrypt's symmetric encrypt/decrypt path end-to-end.
# @timeout: 120
# @tags: usage, gpg, symmetric, roundtrip, aes256, r18
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'round18 symmetric payload\n' >"$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'p4ssw0rd-r18' \
    --cipher-algo AES256 \
    --symmetric --output "$tmpdir/cipher.gpg" "$tmpdir/plain.txt" \
    2>"$tmpdir/enc.err"

validator_require_file "$tmpdir/cipher.gpg"

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'p4ssw0rd-r18' \
    --decrypt --output "$tmpdir/decrypted.txt" "$tmpdir/cipher.gpg" \
    2>"$tmpdir/dec.err"

if ! cmp -s "$tmpdir/plain.txt" "$tmpdir/decrypted.txt"; then
  echo 'symmetric roundtrip failed: decrypted differs from plaintext' >&2
  diff -u "$tmpdir/plain.txt" "$tmpdir/decrypted.txt" >&2 || true
  exit 1
fi
