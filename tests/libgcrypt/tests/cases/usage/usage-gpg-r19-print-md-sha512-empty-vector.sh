#!/usr/bin/env bash
# @testcase: usage-gpg-r19-print-md-sha512-empty-vector
# @title: gpg --print-md SHA512 of the empty input matches the FIPS-180 KAT
# @description: Hashes a zero-byte input with gpg --print-md SHA512 and asserts the lowercase hex digest equals the published FIPS-180 SHA-512 KAT cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e, exercising libgcrypt's SHA-512 path on the empty message.
# @timeout: 60
# @tags: usage, gpg, print-md, sha512, kat, r19
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/in.bin"
gpg --print-md SHA512 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:128}
expected='cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA512(empty)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
