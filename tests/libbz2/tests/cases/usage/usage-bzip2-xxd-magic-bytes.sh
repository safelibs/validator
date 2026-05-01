#!/usr/bin/env bash
# @testcase: usage-bzip2-xxd-magic-bytes
# @title: bzip2 stream magic bytes via od
# @description: Compresses input with bzip2 -9 and uses od -An -tx1 to verify the first six bytes form the expected BZh9 + pi-block magic (42 5a 68 39 31 41).
# @timeout: 120
# @tags: usage, bzip2, format, magic
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'magic byte probe payload\n' >"$tmpdir/in.txt"
bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"

# od -An -tx1 produces space-separated lowercase hex bytes; squash to a single
# stream and compare the first 12 hex chars (= 6 bytes).
hex=$(od -An -tx1 "$tmpdir/in.bz2" | tr -d ' \n' | head -c 12)
case "$hex" in
  "425a683931"*) ;;
  *)
    printf 'expected leading hex 425a683931..., got %s\n' "$hex" >&2
    od -An -tx1 "$tmpdir/in.bz2" | head -2 >&2 || true
    exit 1
    ;;
esac

# Verify the 6th byte is the bzip2 compressed-block start magic (0x41).
sixth=${hex:10:2}
[[ "$sixth" == "41" ]] || {
  printf 'expected 6th byte 41 (block magic), got %s\n' "$sixth" >&2
  od -An -tx1 "$tmpdir/in.bz2" | head -2 >&2 || true
  exit 1
}

# The first three bytes spell "BZh" in ASCII; verify by reading them.
prefix=$(head -c 3 "$tmpdir/in.bz2")
[[ "$prefix" == "BZh" ]] || {
  printf 'expected ASCII "BZh" prefix, got %q\n' "$prefix" >&2
  exit 1
}
