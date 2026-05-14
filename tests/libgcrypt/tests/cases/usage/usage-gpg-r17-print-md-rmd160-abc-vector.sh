#!/usr/bin/env bash
# @testcase: usage-gpg-r17-print-md-rmd160-abc-vector
# @title: gpg --print-md RMD160 of "abc" matches the published RIPEMD-160 KAT
# @description: Hashes the three-byte payload "abc" with gpg --print-md RMD160 and asserts the lowercase hex digest equals the published RIPEMD-160 known-answer 8eb208f7e05d987a9b044a8e98c6b087f15a0bfc, exercising libgcrypt's RIPEMD-160 implementation on a fixed-input KAT, using a stem distinct from the older ripemd160-kat-abc test.
# @timeout: 60
# @tags: usage, gpg, print-md, rmd160, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'abc' >"$tmpdir/in.bin"

gpg --print-md RMD160 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:40}
expected='8eb208f7e05d987a9b044a8e98c6b087f15a0bfc'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected RMD160(abc)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
