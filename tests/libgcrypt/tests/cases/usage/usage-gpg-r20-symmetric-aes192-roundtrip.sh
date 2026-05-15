#!/usr/bin/env bash
# @testcase: usage-gpg-r20-symmetric-aes192-roundtrip
# @title: gpg --symmetric --cipher-algo AES192 roundtrips a 512-byte plaintext
# @description: Encrypts 512 bytes of random data via gpg --symmetric --cipher-algo AES192 with a fixed passphrase under --pinentry-mode loopback, decrypts the resulting ciphertext, and asserts the recovered bytes match the original byte-for-byte - locking in libgcrypt's AES-192 symmetric encrypt/decrypt path (distinct from the existing AES128 and AES256 r19/r18 coverage).
# @timeout: 120
# @tags: usage, gpg, symmetric, aes192, roundtrip, r20
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

head -c 512 /dev/urandom >"$tmpdir/plain.bin"
[[ "$(wc -c <"$tmpdir/plain.bin")" -eq 512 ]] || { echo 'fixture wrong size' >&2; exit 1; }

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'r20-aes192-pass' \
    --cipher-algo AES192 \
    --symmetric --output "$tmpdir/cipher.gpg" "$tmpdir/plain.bin" \
    2>"$tmpdir/enc.err"
validator_require_file "$tmpdir/cipher.gpg"

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'r20-aes192-pass' \
    --decrypt --output "$tmpdir/decrypted.bin" "$tmpdir/cipher.gpg" \
    2>"$tmpdir/dec.err"

cmp -s "$tmpdir/plain.bin" "$tmpdir/decrypted.bin" || {
    echo 'AES192 symmetric roundtrip failed' >&2
    exit 1
}
