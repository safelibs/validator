#!/usr/bin/env bash
# @testcase: usage-gpg-r16-print-md-sha1-abc-vector
# @title: gpg --print-md SHA1 of "abc" matches the FIPS-180 known-answer
# @description: Hashes the three-byte payload "abc" with gpg --print-md SHA1 and asserts the lowercase hex digest equals the canonical FIPS-180 SHA-1 known-answer a9993e364706816aba3e25717850c26c9cd0d89d, exercising libgcrypt's SHA-1 implementation on a fixed-input KAT.
# @timeout: 60
# @tags: usage, gpg, print-md, sha1, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'abc' >"$tmpdir/in.bin"

gpg --print-md SHA1 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C awk -F: '/in\.bin:/ {hex=$2; gsub(/[[:space:]]/, "", hex); print tolower(hex); exit}' "$tmpdir/out")
expected='a9993e364706816aba3e25717850c26c9cd0d89d'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA1(abc)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
