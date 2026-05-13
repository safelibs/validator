#!/usr/bin/env bash
# @testcase: usage-gpg-r16-print-md-sha512-empty-vector
# @title: gpg --print-md SHA512 of an empty input matches the published KAT
# @description: Hashes a zero-byte input with gpg --print-md SHA512 and asserts the lowercase hex digest equals the canonical SHA-512 known-answer for the empty string cf83e1357eefb8bd...3e85a6b3b1fa3 (truncated in description, full value is enforced), exercising libgcrypt's SHA-512 implementation on a fixed-input KAT. Extracts only the file-prefixed digest line via awk.
# @timeout: 60
# @tags: usage, gpg, print-md, sha512, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/empty.bin"
[[ "$(wc -c <"$tmpdir/empty.bin")" -eq 0 ]]

gpg --print-md SHA512 "$tmpdir/empty.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C awk -F: '/empty\.bin:/ {hex=$2; gsub(/[[:space:]]/, "", hex); print tolower(hex); exit}' "$tmpdir/out")
expected='cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA512(empty)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
