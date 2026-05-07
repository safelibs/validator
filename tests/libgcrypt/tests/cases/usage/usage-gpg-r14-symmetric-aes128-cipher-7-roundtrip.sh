#!/usr/bin/env bash
# @testcase: usage-gpg-r14-symmetric-aes128-cipher-7-roundtrip
# @title: gpg --symmetric --cipher-algo AES128 round-trips and records cipher 7 in the symkey-enc packet
# @description: Symmetrically encrypts a fixed payload with --cipher-algo AES128 and a passphrase under an ephemeral GNUPGHOME, asserts the resulting symkey-enc packet declares cipher 7 (AES-128 per RFC 4880), then decrypts and asserts the recovered plaintext matches the input via cmp.
# @timeout: 60
# @tags: usage, gpg, symmetric, aes128
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'r14 symmetric aes128 payload\n' >"$tmpdir/plain.txt"
pp='r14-symmetric-aes128-pp'

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --cipher-algo AES128 \
  --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --list-packets "$tmpdir/cipher.gpg" >"$tmpdir/packets" 2>&1

# RFC 4880: cipher 7 = AES-128.
LC_ALL=C grep -E 'symkey enc packet:.*cipher 7\b' "$tmpdir/packets" >/dev/null || {
  echo 'expected cipher 7 (AES-128) in symkey-enc packet' >&2
  cat "$tmpdir/packets" >&2
  exit 1
}

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --decrypt -o "$tmpdir/round.txt" "$tmpdir/cipher.gpg" >/dev/null 2>&1

cmp "$tmpdir/plain.txt" "$tmpdir/round.txt"
