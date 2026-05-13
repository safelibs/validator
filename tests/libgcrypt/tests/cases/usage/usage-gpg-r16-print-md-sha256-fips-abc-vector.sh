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

# The digest line is prefixed with the file path; extract just the hex.
digest=$(LC_ALL=C awk -F: '/in\.bin:/ {hex=$2; gsub(/[[:space:]]/, "", hex); print tolower(hex); exit}' "$tmpdir/out")
expected='ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA256(abc)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
