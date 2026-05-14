#!/usr/bin/env bash
# @testcase: usage-gpg-r17-print-md-md5-abc-vector
# @title: gpg --print-md MD5 of "abc" matches the RFC 1321 known-answer
# @description: Hashes the three-byte payload "abc" with gpg --print-md MD5 and asserts the lowercase hex digest equals the canonical RFC 1321 MD5 known-answer 900150983cd24fb0d6963f7d28e17f72, exercising libgcrypt's MD5 implementation on a fixed-input KAT (distinct from the older "hello" KAT test).
# @timeout: 60
# @tags: usage, gpg, print-md, md5, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'abc' >"$tmpdir/in.bin"

gpg --print-md MD5 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:32}
expected='900150983cd24fb0d6963f7d28e17f72'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected MD5(abc)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
