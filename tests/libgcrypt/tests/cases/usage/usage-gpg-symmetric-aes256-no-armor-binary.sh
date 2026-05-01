#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-aes256-no-armor-binary
# @title: gpg AES256 symmetric --no-armor binary output
# @description: Symmetrically encrypts a payload with --no-armor and asserts the ciphertext begins with an OpenPGP binary packet tag (high bit set), not an armored ASCII header.
# @timeout: 180
# @tags: usage, gpg, crypto, encryption
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-aes256-no-armor-binary"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-no-armor-passphrase

printf 'no-armor binary payload\n' >"$tmpdir/plain.txt"

"${gpg_batch[@]}" --passphrase "$passphrase" --cipher-algo AES256 --no-armor \
  --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
test -s "$tmpdir/plain.gpg"

# Binary OpenPGP packet headers always have bit 7 set in the first byte.
first=$(head -c 1 "$tmpdir/plain.gpg" | od -An -tu1 | tr -d ' \n')
test "$first" -ge 128
# Also confirm it does not look like ASCII armor.
if grep -q 'BEGIN PGP MESSAGE' "$tmpdir/plain.gpg" 2>/dev/null; then
  printf 'expected binary output, found armored header\n' >&2
  exit 1
fi

"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt \
  -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
validator_assert_contains "$tmpdir/out.txt" 'no-armor binary payload'
