#!/usr/bin/env bash
# @testcase: usage-gpg-r19-print-md-sha224-empty-vector
# @title: gpg --print-md SHA224 of the empty input matches the FIPS-180 KAT
# @description: Hashes a zero-byte input with gpg --print-md SHA224 and asserts the lowercase hex digest equals the published FIPS-180 KAT d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f, exercising libgcrypt's SHA-224 implementation on the empty message.
# @timeout: 60
# @tags: usage, gpg, print-md, sha224, kat, r19
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/in.bin"
[[ "$(wc -c <"$tmpdir/in.bin")" -eq 0 ]] || { echo 'fixture not empty' >&2; exit 1; }

gpg --print-md SHA224 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:56}
expected='d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA224(empty)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
