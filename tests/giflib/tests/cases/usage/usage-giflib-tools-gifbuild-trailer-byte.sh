#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-trailer-byte
# @title: gifbuild rebuild ends with GIF trailer byte
# @description: Rebuilds a GIF from a gifbuild text dump and verifies that the final byte of the encoded output is 0x3B, the mandatory GIF stream trailer.
# @timeout: 60
# @tags: usage, cli, gifbuild
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
gifbuild "$tmpdir/dump.txt" >"$tmpdir/rebuilt.gif"

file "$tmpdir/rebuilt.gif" | grep -q 'GIF image data'

last_byte=$(python3 -c '
import sys
with open(sys.argv[1], "rb") as fh:
    data = fh.read()
sys.stdout.write(f"{data[-1]:02x}")
' "$tmpdir/rebuilt.gif")

if [[ "$last_byte" != "3b" ]]; then
  printf 'expected GIF trailer 0x3b, got 0x%s\n' "$last_byte" >&2
  exit 1
fi
