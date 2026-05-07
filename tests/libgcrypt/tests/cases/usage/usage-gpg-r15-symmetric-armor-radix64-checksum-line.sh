#!/usr/bin/env bash
# @testcase: usage-gpg-r15-symmetric-armor-radix64-checksum-line
# @title: gpg --symmetric --armor emits a radix-64 CRC line plus PGP MESSAGE banners
# @description: Symmetrically encrypts a fixed payload with --armor under an ephemeral GNUPGHOME, asserts the output begins with "-----BEGIN PGP MESSAGE-----" and ends with "-----END PGP MESSAGE-----", asserts a radix-64 CRC line of the form '=' followed by exactly four base64 characters appears on its own line, and decrypts back to the original payload via cmp.
# @timeout: 60
# @tags: usage, gpg, symmetric, armor, crc, r15
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'r15 symmetric armor crc payload\n' >"$tmpdir/plain.txt"
pp='r15-armor-crc-pp'

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --armor --symmetric -o "$tmpdir/cipher.asc" "$tmpdir/plain.txt"

LC_ALL=C grep -q '^-----BEGIN PGP MESSAGE-----$' "$tmpdir/cipher.asc"
LC_ALL=C grep -q '^-----END PGP MESSAGE-----$'   "$tmpdir/cipher.asc"
LC_ALL=C grep -E '^=[A-Za-z0-9+/]{4}$' "$tmpdir/cipher.asc" >/dev/null || {
  echo 'no radix-64 CRC line in armored symmetric output' >&2
  cat "$tmpdir/cipher.asc" >&2
  exit 1
}

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --decrypt -o "$tmpdir/round.txt" "$tmpdir/cipher.asc" >/dev/null 2>&1

cmp "$tmpdir/plain.txt" "$tmpdir/round.txt"
