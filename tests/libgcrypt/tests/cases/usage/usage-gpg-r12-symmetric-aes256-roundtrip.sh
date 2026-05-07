#!/usr/bin/env bash
# @testcase: usage-gpg-r12-symmetric-aes256-roundtrip
# @title: gpg --symmetric --cipher-algo AES256 round-trips a payload
# @description: Symmetrically encrypts a fixed payload with --cipher-algo AES256 and a passphrase under an ephemeral GNUPGHOME, decrypts it back with the same passphrase, and asserts the recovered plaintext is byte-identical to the input.
# @timeout: 60
# @tags: usage, gpg, symmetric, aes256
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'r12 aes256 symmetric payload\n' >"$tmpdir/plain.txt"
pp='r12-symmetric-passphrase'

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --cipher-algo AES256 \
  --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

# Confirm the symkey-enc packet uses cipher 9 (AES-256 per RFC 4880).
gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --list-packets "$tmpdir/cipher.gpg" >"$tmpdir/packets" 2>&1
grep -E 'symkey enc packet:.*cipher 9\b' "$tmpdir/packets" >/dev/null || {
  echo 'expected cipher 9 (AES256) in symkey-enc packet' >&2
  cat "$tmpdir/packets" >&2
  exit 1
}

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --decrypt -o "$tmpdir/round.txt" "$tmpdir/cipher.gpg" >/dev/null 2>&1

cmp "$tmpdir/plain.txt" "$tmpdir/round.txt"
