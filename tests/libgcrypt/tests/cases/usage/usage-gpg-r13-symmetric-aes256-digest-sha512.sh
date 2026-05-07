#!/usr/bin/env bash
# @testcase: usage-gpg-r13-symmetric-aes256-digest-sha512
# @title: gpg --symmetric with AES256 and --digest-algo SHA512 round-trips and uses S2K hash 10
# @description: Symmetrically encrypts a payload with --cipher-algo AES256 and --digest-algo SHA512, asserts the resulting symkey-enc packet records cipher 9 (AES-256) and hash 10 (SHA-512), then decrypts the ciphertext and asserts the recovered plaintext matches the original via cmp.
# @timeout: 60
# @tags: usage, gpg, symmetric, aes256, sha512
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'r13 symmetric aes256 sha512 payload\n' >"$tmpdir/plain.txt"
pp='r13-symmetric-pp'

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --cipher-algo AES256 --digest-algo SHA512 \
  --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --list-packets "$tmpdir/cipher.gpg" >"$tmpdir/packets" 2>&1

# RFC 4880: cipher 9 = AES-256; hash 10 = SHA-512.
grep -E 'symkey enc packet:.*cipher 9\b.*hash 10\b' "$tmpdir/packets" >/dev/null || {
  echo 'expected cipher 9 + hash 10 in symkey-enc packet' >&2
  cat "$tmpdir/packets" >&2
  exit 1
}

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --decrypt -o "$tmpdir/round.txt" "$tmpdir/cipher.gpg" >/dev/null 2>&1

cmp "$tmpdir/plain.txt" "$tmpdir/round.txt"
