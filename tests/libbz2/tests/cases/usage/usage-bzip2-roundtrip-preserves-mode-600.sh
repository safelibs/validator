#!/usr/bin/env bash
# @testcase: usage-bzip2-roundtrip-preserves-mode-600
# @title: bzip2 round trip preserves chmod 600
# @description: Compresses a 0600-mode file in place and decompresses it back, verifying bzip2 carries the restrictive permission bits across the round trip.
# @timeout: 180
# @tags: usage, bzip2, permissions
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-roundtrip-preserves-mode-600"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Make sure the umask cannot mask the bits we care about.
umask 022

printf 'private payload\nline two\n' >"$tmpdir/secret.txt"
chmod 600 "$tmpdir/secret.txt"

# Sanity: the source must really be 0600 before we measure anything.
src_mode=$(stat -c '%a' "$tmpdir/secret.txt")
[[ "$src_mode" == "600" ]] || {
  printf 'expected source mode 600, got %s\n' "$src_mode" >&2
  exit 1
}

# Compress in place; bzip2 should propagate the 0600 mode onto secret.txt.bz2.
bzip2 "$tmpdir/secret.txt"
validator_require_file "$tmpdir/secret.txt.bz2"
bz_mode=$(stat -c '%a' "$tmpdir/secret.txt.bz2")
[[ "$bz_mode" == "600" ]] || {
  printf 'expected compressed mode 600, got %s\n' "$bz_mode" >&2
  exit 1
}

# Decompress back; the restored file must again be 0600.
bzip2 -d "$tmpdir/secret.txt.bz2"
validator_require_file "$tmpdir/secret.txt"
restored_mode=$(stat -c '%a' "$tmpdir/secret.txt")
[[ "$restored_mode" == "600" ]] || {
  printf 'expected restored mode 600, got %s\n' "$restored_mode" >&2
  exit 1
}

validator_assert_contains "$tmpdir/secret.txt" 'private payload'
