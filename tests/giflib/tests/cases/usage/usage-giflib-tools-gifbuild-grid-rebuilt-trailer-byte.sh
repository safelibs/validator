#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-grid-rebuilt-trailer-byte
# @title: gifbuild rebuilt gifgrid.gif still terminates with 0x3b
# @description: Dumps gifgrid.gif via gifbuild -d, rebuilds it through gifbuild, and asserts the rebuilt stream is a recognized GIF whose final byte is the mandatory 0x3b trailer marker, complementing the existing trailer check on treescap.
# @timeout: 60
# @tags: usage, cli, gifbuild, trailer
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
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
  printf 'expected GIF trailer 0x3b on rebuilt gifgrid, got 0x%s\n' "$last_byte" >&2
  exit 1
fi
