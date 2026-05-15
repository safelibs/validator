#!/usr/bin/env bash
# @testcase: usage-gpg-r19-print-md-sha1-empty-vector
# @title: gpg --print-md SHA1 of the empty input matches the RFC 3174 KAT
# @description: Hashes a zero-byte input with gpg --print-md SHA1 and asserts the lowercase hex digest equals the canonical SHA-1 empty-string KAT da39a3ee5e6b4b0d3255bfef95601890afd80709, exercising libgcrypt's SHA-1 path on the empty message.
# @timeout: 60
# @tags: usage, gpg, print-md, sha1, kat, empty, r19
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/in.bin"
gpg --print-md SHA1 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:40}
expected='da39a3ee5e6b4b0d3255bfef95601890afd80709'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA1(empty)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
