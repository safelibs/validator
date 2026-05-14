#!/usr/bin/env bash
# @testcase: usage-gpg-r18-print-md-sha256-abcdbcde-vector
# @title: gpg --print-md SHA256 of FIPS-180 56-byte abcdbcde test vector matches KAT
# @description: Hashes the 56-byte FIPS-180 SHA-256 test message "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" via gpg --print-md SHA256 and asserts the lowercase hex digest equals the published KAT 248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1, exercising libgcrypt's SHA-256 on a multi-block input distinct from the abc vector.
# @timeout: 60
# @tags: usage, gpg, print-md, sha256, kat, r18
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq' >"$tmpdir/in.bin"
[[ "$(wc -c <"$tmpdir/in.bin")" -eq 56 ]] || { echo 'fixture wrong size' >&2; exit 1; }

gpg --print-md SHA256 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:64}
expected='248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA256(56-byte vector)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
