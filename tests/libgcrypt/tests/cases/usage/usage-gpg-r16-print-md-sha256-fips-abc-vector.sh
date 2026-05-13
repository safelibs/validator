#!/usr/bin/env bash
# @testcase: usage-gpg-r16-print-md-sha256-fips-abc-vector
# @title: gpg --print-md SHA256 of "abc" matches the FIPS-180 known-answer
# @description: Hashes the three-byte payload "abc" with gpg --print-md SHA256 and asserts the lowercase hex digest equals the canonical FIPS-180 SHA-256 known-answer ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad, exercising libgcrypt's SHA-256 implementation on a fixed-input KAT. Extracts only the file-prefixed digest line via awk to skip any keybox-creation notice.
# @timeout: 60
# @tags: usage, gpg, print-md, sha256, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'abc' >"$tmpdir/in.bin"

gpg --print-md SHA256 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

# gpg --print-md wraps long digests across multiple lines. The first line
# is prefixed by the file path (which may contain hex-like letters), so we
# drop the prefix up to and including the first colon-then-space, then strip
# everything except hex characters from the remainder.
digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:64}
expected='ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA256(abc)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
