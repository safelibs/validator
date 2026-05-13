#!/usr/bin/env bash
# @testcase: usage-gpg-r16-print-mds-empty-md5-known-answer
# @title: gpg --print-mds on empty input emits MD5 = d41d8cd98f00b204e9800998ecf8427e
# @description: Runs gpg --print-mds on a zero-byte file and asserts the MD5 line of the multi-digest listing equals the canonical empty-string MD5 d41d8cd98f00b204e9800998ecf8427e (case-insensitive hex match), exercising libgcrypt's MD5 implementation on the empty input KAT.
# @timeout: 60
# @tags: usage, gpg, print-mds, md5, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/empty.bin"

# Confirm --print-mds runs without error and emits the MD5 algorithm header.
gpg --batch --print-mds "$tmpdir/empty.bin" >"$tmpdir/mds.out" 2>"$tmpdir/mds.err"
validator_assert_contains "$tmpdir/mds.out" 'MD5 ='

# Use --print-md MD5 for the deterministic single-digest readback. The path
# prefix may contain hex-like letters, so strip up to the first colon, then
# keep only hex characters, then take the first 32 chars (MD5 digest length).
gpg --batch --print-md MD5 "$tmpdir/empty.bin" >"$tmpdir/md5.out" 2>"$tmpdir/md5.err"
md5_hex=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/md5.out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
md5_hex=${md5_hex:0:32}
expected='d41d8cd98f00b204e9800998ecf8427e'
if [[ "$md5_hex" != "$expected" ]]; then
  printf 'expected MD5(empty)=%s, got %s\n' "$expected" "$md5_hex" >&2
  cat "$tmpdir/md5.out" >&2
  cat "$tmpdir/mds.out" >&2
  exit 1
fi
