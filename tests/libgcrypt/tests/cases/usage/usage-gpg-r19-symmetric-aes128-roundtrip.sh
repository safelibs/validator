#!/usr/bin/env bash
# @testcase: usage-gpg-r19-symmetric-aes128-roundtrip
# @title: gpg --symmetric --cipher-algo AES128 roundtrips a binary plaintext byte-for-byte
# @description: Encrypts a 1 KiB pseudo-random plaintext (built from /dev/urandom) via gpg --symmetric with AES128 and a fixed passphrase via --pinentry-mode loopback, decrypts the resulting ciphertext, and asserts the recovered bytes match the original byte-for-byte, exercising libgcrypt's AES-128 symmetric encrypt/decrypt path (distinct from the r18 AES-256 coverage).
# @timeout: 120
# @tags: usage, gpg, symmetric, aes128, roundtrip, r19
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

# 1 KiB of random bytes from the kernel.
head -c 1024 /dev/urandom >"$tmpdir/plain.bin"
[[ "$(wc -c <"$tmpdir/plain.bin")" -eq 1024 ]] || { echo 'fixture wrong size' >&2; exit 1; }

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'r19-aes128-pass' \
    --cipher-algo AES128 \
    --symmetric --output "$tmpdir/cipher.gpg" "$tmpdir/plain.bin" \
    2>"$tmpdir/enc.err"
validator_require_file "$tmpdir/cipher.gpg"

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'r19-aes128-pass' \
    --decrypt --output "$tmpdir/decrypted.bin" "$tmpdir/cipher.gpg" \
    2>"$tmpdir/dec.err"

if ! cmp -s "$tmpdir/plain.bin" "$tmpdir/decrypted.bin"; then
  echo 'AES128 symmetric roundtrip failed' >&2
  exit 1
fi
