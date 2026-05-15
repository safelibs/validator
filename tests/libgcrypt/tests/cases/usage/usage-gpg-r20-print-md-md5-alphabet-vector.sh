#!/usr/bin/env bash
# @testcase: usage-gpg-r20-print-md-md5-alphabet-vector
# @title: gpg --print-md MD5 of "abcdefghijklmnopqrstuvwxyz" matches RFC 1321 KAT
# @description: Pipes the 26-byte ASCII lowercase alphabet to gpg --print-md MD5 and asserts the captured lowercase hex digest equals c3fcd3d76192e4007dfb496cca67e13b (RFC 1321 known-answer) - locking in libgcrypt's MD5 path on the alphabet KAT, distinct from earlier rounds' "abc" and empty-input MD5 coverage.
# @timeout: 60
# @tags: usage, gpg, print-md, md5, alphabet, r20
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

digest=$(printf 'abcdefghijklmnopqrstuvwxyz' | gpg --print-md MD5 \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:32}
expected='c3fcd3d76192e4007dfb496cca67e13b'
[[ "$digest" == "$expected" ]] || {
    printf 'expected MD5(alphabet)=%s, got %s\n' "$expected" "$digest" >&2
    exit 1
}
