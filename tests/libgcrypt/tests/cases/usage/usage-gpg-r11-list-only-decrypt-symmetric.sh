#!/usr/bin/env bash
# @testcase: usage-gpg-r11-list-only-decrypt-symmetric
# @title: gpg --list-only --decrypt of symmetric stream prints AES diagnostic without writing plaintext
# @description: Symmetrically encrypts a payload, then runs --list-only --decrypt and verifies stderr contains the "AES256.CFB encrypted data" diagnostic line while stdout stays empty (no plaintext is materialised).
# @timeout: 60
# @tags: usage, gpg, list-only, decrypt
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'list-only secret payload\n' >"$tmpdir/plain.txt"
gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --list-only --decrypt "$tmpdir/cipher.gpg" \
  >"$tmpdir/out.bin" 2>"$tmpdir/err.txt"

[[ ! -s "$tmpdir/out.bin" ]] || {
  echo '--list-only --decrypt unexpectedly produced stdout' >&2
  hexdump -C "$tmpdir/out.bin" | head >&2
  exit 1
}

grep -q 'AES256\.CFB encrypted data' "$tmpdir/err.txt" || {
  echo 'expected AES256.CFB diagnostic on stderr' >&2
  cat "$tmpdir/err.txt" >&2
  exit 1
}
