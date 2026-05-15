#!/usr/bin/env bash
# @testcase: usage-gpg-r20-print-md-ripemd160-empty-vector
# @title: gpg --print-md RIPEMD160 of empty input matches the canonical KAT
# @description: Pipes a zero-byte file to gpg --print-md RIPEMD160 and asserts the captured lowercase hex digest equals 9c1185a5c5e9fc54612808977ee8f548b2258d31 - locking in libgcrypt's RIPEMD160 path on the empty-input boundary (distinct from prior rounds' abc and "hello" RIPEMD160 KAT coverage).
# @timeout: 60
# @tags: usage, gpg, print-md, ripemd160, empty, r20
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/empty.bin"
[[ "$(wc -c <"$tmpdir/empty.bin")" -eq 0 ]] || { echo 'fixture not empty' >&2; exit 1; }

gpg --print-md RIPEMD160 "$tmpdir/empty.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:40}
expected='9c1185a5c5e9fc54612808977ee8f548b2258d31'
[[ "$digest" == "$expected" ]] || {
    printf 'expected RIPEMD160(empty)=%s, got %s\n' "$expected" "$digest" >&2
    cat "$tmpdir/out" >&2
    exit 1
}
