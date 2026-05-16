#!/usr/bin/env bash
# @testcase: usage-gpg-r21-symmetric-camellia128-roundtrip
# @title: gpg --symmetric --cipher-algo CAMELLIA128 roundtrips a 384-byte payload
# @description: Encrypts 384 bytes of /dev/urandom output with gpg --symmetric --cipher-algo CAMELLIA128 under --pinentry-mode loopback with a fixed passphrase, decrypts the ciphertext, and asserts the recovered bytes match the original byte-for-byte - locking in libgcrypt's CAMELLIA-128 symmetric encrypt/decrypt path (existing rounds covered CAMELLIA192 and CAMELLIA256 roundtrips but not the 128-bit variant via a roundtrip).
# @timeout: 120
# @tags: usage, gpg, symmetric, camellia128, roundtrip, r21
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

head -c 384 /dev/urandom >"$tmpdir/plain.bin"
[[ "$(wc -c <"$tmpdir/plain.bin")" -eq 384 ]] || { echo 'fixture wrong size' >&2; exit 1; }

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'r21-camellia128-pass' \
    --cipher-algo CAMELLIA128 \
    --symmetric --output "$tmpdir/cipher.gpg" "$tmpdir/plain.bin" \
    2>"$tmpdir/enc.err"
validator_require_file "$tmpdir/cipher.gpg"

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'r21-camellia128-pass' \
    --decrypt --output "$tmpdir/decrypted.bin" "$tmpdir/cipher.gpg" \
    2>"$tmpdir/dec.err"

cmp -s "$tmpdir/plain.bin" "$tmpdir/decrypted.bin" || {
    echo 'CAMELLIA128 symmetric roundtrip failed' >&2
    exit 1
}
