#!/usr/bin/env bash
# @testcase: usage-gpg-r19-print-md-md5-empty-vector
# @title: gpg --print-md MD5 of the empty input matches the RFC 1321 KAT
# @description: Hashes a zero-byte input with gpg --print-md MD5 and asserts the lowercase hex digest equals the canonical RFC 1321 MD5 empty-string KAT d41d8cd98f00b204e9800998ecf8427e, exercising libgcrypt's MD5 path on the empty message.
# @timeout: 60
# @tags: usage, gpg, print-md, md5, kat, empty, r19
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/in.bin"
gpg --print-md MD5 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:32}
expected='d41d8cd98f00b204e9800998ecf8427e'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected MD5(empty)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
