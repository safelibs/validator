#!/usr/bin/env bash
# @testcase: usage-gpg-r19-symmetric-armor-line-shape
# @title: gpg --symmetric --armor output opens and closes with PGP MESSAGE delimiters
# @description: Encrypts a short fixed plaintext via gpg --symmetric --armor with AES256 and a fixed passphrase, then asserts the resulting ASCII-armored output starts with the literal "-----BEGIN PGP MESSAGE-----" header line and ends with the matching "-----END PGP MESSAGE-----" trailer, exercising libgcrypt's armored output framing through gpg.
# @timeout: 120
# @tags: usage, gpg, symmetric, armor, message, r19
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'armor-shape-r19\n' >"$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'armor-r19' \
    --cipher-algo AES256 \
    --armor --symmetric --output "$tmpdir/cipher.asc" "$tmpdir/plain.txt" \
    2>"$tmpdir/enc.err"
validator_require_file "$tmpdir/cipher.asc"

first=$(LC_ALL=C grep -m1 -v '^[[:space:]]*$' "$tmpdir/cipher.asc" || true)
if [[ "$first" != '-----BEGIN PGP MESSAGE-----' ]]; then
  printf 'expected BEGIN PGP MESSAGE first line, got: %s\n' "$first" >&2
  head -n5 "$tmpdir/cipher.asc" >&2
  exit 1
fi
last=$(LC_ALL=C grep -E '^-----END PGP MESSAGE-----$' "$tmpdir/cipher.asc" || true)
if [[ -z "$last" ]]; then
  echo 'missing END PGP MESSAGE trailer' >&2
  tail -n5 "$tmpdir/cipher.asc" >&2
  exit 1
fi
