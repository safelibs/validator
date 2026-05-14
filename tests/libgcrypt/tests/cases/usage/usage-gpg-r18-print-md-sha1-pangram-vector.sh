#!/usr/bin/env bash
# @testcase: usage-gpg-r18-print-md-sha1-pangram-vector
# @title: gpg --print-md SHA1 of the quick-brown-fox pangram matches the canonical KAT
# @description: Hashes the canonical 43-byte pangram "The quick brown fox jumps over the lazy dog" with gpg --print-md SHA1 and asserts the lowercase hex digest equals 2fd4e1c67a2d28fced849ee1bb76e7391b93eb12, exercising libgcrypt's SHA-1 implementation on a known KAT distinct from abc and empty-string vectors.
# @timeout: 60
# @tags: usage, gpg, print-md, sha1, pangram, kat, r18
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'The quick brown fox jumps over the lazy dog' >"$tmpdir/in.bin"
[[ "$(wc -c <"$tmpdir/in.bin")" -eq 43 ]] || { echo 'pangram fixture wrong size' >&2; exit 1; }

gpg --print-md SHA1 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:40}
expected='2fd4e1c67a2d28fced849ee1bb76e7391b93eb12'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA1(pangram)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
