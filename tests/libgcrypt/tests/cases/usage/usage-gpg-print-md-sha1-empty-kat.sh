#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-sha1-empty-kat
# @title: gpg print-md SHA1 empty input KAT
# @description: Verifies gpg --print-md SHA1 emits the canonical da39a3ee... known-answer digest for an empty input file.
# @timeout: 120
# @tags: usage, gpg, digest, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-sha1-empty-kat"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/empty.bin"
test ! -s "$tmpdir/empty.bin"

gpg --print-md SHA1 "$tmpdir/empty.bin" >"$tmpdir/out"

# Canonical SHA-1 of the empty string: da39a3ee5e6b4b0d3255bfef95601890afd80709
hex=$(tr -d ' \t\n' <"$tmpdir/out" | sed 's/^.*://')
test "$hex" = "DA39A3EE5E6B4B0D3255BFEF95601890AFD80709"

validator_assert_contains "$tmpdir/out" 'empty.bin:'
# The print-md format may wrap the hex groups across two lines depending on
# the filename length; collapse all whitespace before checking the digest tail.
tr -s ' \t\n' ' ' <"$tmpdir/out" >"$tmpdir/out.norm"
grep -Fq -- 'DA39 A3EE 5E6B 4B0D 3255' "$tmpdir/out.norm" || {
  printf 'expected SHA1 digest head in normalized output\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
grep -Fq -- 'BFEF 9560 1890 AFD8 0709' "$tmpdir/out.norm" || {
  printf 'expected SHA1 digest tail in normalized output\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
