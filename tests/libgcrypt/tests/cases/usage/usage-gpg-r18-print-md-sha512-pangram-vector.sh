#!/usr/bin/env bash
# @testcase: usage-gpg-r18-print-md-sha512-pangram-vector
# @title: gpg --print-md SHA512 of the quick-brown-fox pangram matches the canonical KAT
# @description: Hashes the canonical 43-byte pangram "The quick brown fox jumps over the lazy dog" with gpg --print-md SHA512 and asserts the lowercase hex digest equals 07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6, exercising libgcrypt's SHA-512 on a known KAT distinct from the empty and abc vectors.
# @timeout: 60
# @tags: usage, gpg, print-md, sha512, pangram, kat, r18
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

gpg --print-md SHA512 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:128}
expected='07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA512(pangram)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
