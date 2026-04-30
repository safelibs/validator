#!/usr/bin/env bash
# @testcase: usage-bzip2-roundtrip-preserves-setuid
# @title: bzip2 round-trip preserves restrictive 0600 mode bits
# @description: Marks a regular file with chmod 0600 (owner-only read/write), compresses it in place, decompresses it back, and verifies bzip2 carries the restrictive mode bits across the round trip on both the .bz2 and the restored plaintext (the standard mode-preservation path; bzip2 deliberately strips setuid/setgid for safety).
# @timeout: 180
# @tags: usage, bzip2, permissions
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Avoid umask masking the bits we want to measure.
umask 022

printf 'restricted payload\nsecond line\n' >"$tmpdir/binstub"
chmod 0600 "$tmpdir/binstub"

src_mode=$(stat -c '%a' "$tmpdir/binstub")
[[ "$src_mode" == "600" ]] || {
  printf 'expected source mode 600, got %s\n' "$src_mode" >&2
  exit 1
}

# Compress in place; bzip2 should propagate the mode bits onto the .bz2.
bzip2 "$tmpdir/binstub"
validator_require_file "$tmpdir/binstub.bz2"
[[ ! -e "$tmpdir/binstub" ]] || {
  printf 'original file should have been replaced by .bz2\n' >&2
  exit 1
}

bz_mode=$(stat -c '%a' "$tmpdir/binstub.bz2")
[[ "$bz_mode" == "600" ]] || {
  printf 'expected compressed mode 600, got %s\n' "$bz_mode" >&2
  exit 1
}

# Decompress; the restored file must again be 600.
bzip2 -d "$tmpdir/binstub.bz2"
validator_require_file "$tmpdir/binstub"
restored_mode=$(stat -c '%a' "$tmpdir/binstub")
[[ "$restored_mode" == "600" ]] || {
  printf 'expected restored mode 600, got %s\n' "$restored_mode" >&2
  exit 1
}

validator_assert_contains "$tmpdir/binstub" 'restricted payload'
