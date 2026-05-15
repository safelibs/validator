#!/usr/bin/env bash
# @testcase: usage-gpg-r19-print-md-sha256-empty-vector
# @title: gpg --print-md SHA256 of the empty input matches the FIPS-180 KAT
# @description: Hashes a zero-byte input with gpg --print-md SHA256 and asserts the lowercase hex digest equals the published FIPS-180 SHA-256 KAT e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855, exercising libgcrypt's SHA-256 path on the canonical empty-message vector.
# @timeout: 60
# @tags: usage, gpg, print-md, sha256, kat, empty, r19
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/in.bin"
gpg --print-md SHA256 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:64}
expected='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA256(empty)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
