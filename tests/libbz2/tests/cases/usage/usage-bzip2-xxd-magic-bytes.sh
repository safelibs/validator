#!/usr/bin/env bash
# @testcase: usage-bzip2-xxd-magic-bytes
# @title: bzip2 stream magic bytes via xxd
# @description: Compresses input with bzip2 -9 and uses xxd | head to verify the first six bytes form the expected BZh9 + pi-block magic (42 5a 68 39 31 41).
# @timeout: 120
# @tags: usage, bzip2, format, xxd
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

command -v xxd >/dev/null 2>&1 || {
  printf 'xxd is not available\n' >&2
  exit 1
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'magic byte probe payload\n' >"$tmpdir/in.txt"
bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"

# xxd -p produces a continuous hex stream; head -c 12 gives 6 bytes.
hex=$(xxd -p "$tmpdir/in.bz2" | tr -d '\n' | head -c 12)
case "$hex" in
  "425a683931"*) ;;
  *)
    printf 'expected leading hex 425a683931..., got %s\n' "$hex" >&2
    xxd "$tmpdir/in.bz2" | head -2 >&2 || true
    exit 1
    ;;
esac

# Verify the 6th byte is the bzip2 compressed-block start magic (0x41).
sixth=$(xxd -p "$tmpdir/in.bz2" | tr -d '\n' | head -c 12 | tail -c 2)
[[ "$sixth" == "41" ]] || {
  printf 'expected 6th byte 41 (block magic), got %s\n' "$sixth" >&2
  xxd "$tmpdir/in.bz2" | head -2 >&2 || true
  exit 1
}

# And xxd | head -1 must report the BZh9 ASCII rendering on the right.
xxd "$tmpdir/in.bz2" | head -1 >"$tmpdir/first"
validator_assert_contains "$tmpdir/first" "BZh9"
