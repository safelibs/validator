#!/usr/bin/env bash
# @testcase: usage-gpg-armor-vs-binary-magic
# @title: gpg armor vs binary output magic
# @description: Symmetrically encrypts the same payload as armored ASCII and as binary, then checks the file magic distinguishes them.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-armor-vs-binary-magic"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-armor-passphrase

printf 'armor vs binary payload\n' >"$tmpdir/plain.txt"

"${gpg_batch[@]}" --passphrase "$passphrase" --cipher-algo AES256 \
  --armor --symmetric -o "$tmpdir/cipher.asc" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase "$passphrase" --cipher-algo AES256 \
  --symmetric -o "$tmpdir/cipher.bin" "$tmpdir/plain.txt"

# Armored output begins with the literal PGP MESSAGE header line.
head -n 1 "$tmpdir/cipher.asc" >"$tmpdir/asc-head"
validator_assert_contains "$tmpdir/asc-head" '-----BEGIN PGP MESSAGE-----'

# Binary OpenPGP packets start with a tag byte whose top bit is set
# (>= 0x80). The dashed armor header byte is 0x2D.
first_byte=$(head -c 1 "$tmpdir/cipher.bin" | od -An -tx1 | tr -d ' \n')
test -n "$first_byte"
val=$((16#${first_byte}))
test "$val" -ge 128
test "$first_byte" != "2d"

# Both must decrypt to the original bytes.
"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt \
  -o "$tmpdir/out.asc.txt" "$tmpdir/cipher.asc"
"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt \
  -o "$tmpdir/out.bin.txt" "$tmpdir/cipher.bin"
cmp -s "$tmpdir/plain.txt" "$tmpdir/out.asc.txt"
cmp -s "$tmpdir/plain.txt" "$tmpdir/out.bin.txt"
