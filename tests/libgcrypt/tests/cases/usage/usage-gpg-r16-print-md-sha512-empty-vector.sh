#!/usr/bin/env bash
# @testcase: usage-gpg-r16-print-md-sha512-empty-vector
# @title: gpg --print-md SHA512 of an empty input matches the published KAT
# @description: Hashes a zero-byte input with gpg --print-md SHA512 and asserts the lowercase hex digest equals the canonical SHA-512 known-answer for the empty string cf83e1357eefb8bd...3e85a6b3b1fa3 (truncated in description, full value is enforced), exercising libgcrypt's SHA-512 implementation on a fixed-input KAT. Extracts only the file-prefixed digest line via awk.
# @timeout: 60
# @tags: usage, gpg, print-md, sha512, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/empty.bin"
[[ "$(wc -c <"$tmpdir/empty.bin")" -eq 0 ]]

gpg --print-md SHA512 "$tmpdir/empty.bin" >"$tmpdir/out" 2>"$tmpdir/err"

# gpg --print-md wraps long digests across multiple lines. The first line
# is prefixed by the file path (which may contain hex-like letters), so we
# drop the prefix up to and including the first colon-then-space, then strip
# everything except hex characters from the remainder.
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
