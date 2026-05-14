#!/usr/bin/env bash
# @testcase: usage-gpg-r17-print-md-sha384-empty-vector
# @title: gpg --print-md SHA384 of an empty input matches the published KAT
# @description: Hashes a zero-byte input with gpg --print-md SHA384 and asserts the lowercase hex digest equals the canonical SHA-384 known-answer 38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b, exercising libgcrypt's SHA-384 implementation on a fixed-input KAT.
# @timeout: 60
# @tags: usage, gpg, print-md, sha384, kat
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

gpg --print-md SHA384 "$tmpdir/empty.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:96}
expected='38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA384(empty)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
