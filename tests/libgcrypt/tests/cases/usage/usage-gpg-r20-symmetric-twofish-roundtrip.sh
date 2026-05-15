#!/usr/bin/env bash
# @testcase: usage-gpg-r20-symmetric-twofish-roundtrip
# @title: gpg --symmetric --cipher-algo TWOFISH roundtrips a 768-byte plaintext
# @description: Encrypts 768 bytes of random data via gpg --symmetric --cipher-algo TWOFISH with a fixed passphrase under --pinentry-mode loopback, decrypts the resulting ciphertext, and asserts the recovered bytes match the original byte-for-byte - locking in libgcrypt's Twofish symmetric encrypt/decrypt path at a size distinct from prior rounds.
# @timeout: 120
# @tags: usage, gpg, symmetric, twofish, roundtrip, r20
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

head -c 768 /dev/urandom >"$tmpdir/plain.bin"
[[ "$(wc -c <"$tmpdir/plain.bin")" -eq 768 ]] || { echo 'fixture wrong size' >&2; exit 1; }

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'r20-twofish-pass' \
    --cipher-algo TWOFISH \
    --symmetric --output "$tmpdir/cipher.gpg" "$tmpdir/plain.bin" \
    2>"$tmpdir/enc.err"
validator_require_file "$tmpdir/cipher.gpg"

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'r20-twofish-pass' \
    --decrypt --output "$tmpdir/decrypted.bin" "$tmpdir/cipher.gpg" \
    2>"$tmpdir/dec.err"

cmp -s "$tmpdir/plain.bin" "$tmpdir/decrypted.bin" || {
    echo 'TWOFISH symmetric roundtrip failed' >&2
    exit 1
}
