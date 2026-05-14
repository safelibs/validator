#!/usr/bin/env bash
# @testcase: usage-gpg-r17-print-md-sha224-abc-vector
# @title: gpg --print-md SHA224 of "abc" matches the FIPS-180 known-answer
# @description: Hashes the three-byte payload "abc" with gpg --print-md SHA224 and asserts the lowercase hex digest equals the canonical FIPS-180 SHA-224 known-answer 23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7, exercising libgcrypt's SHA-224 implementation on a fixed-input KAT.
# @timeout: 60
# @tags: usage, gpg, print-md, sha224, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'abc' >"$tmpdir/in.bin"

gpg --print-md SHA224 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:56}
expected='23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA224(abc)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
