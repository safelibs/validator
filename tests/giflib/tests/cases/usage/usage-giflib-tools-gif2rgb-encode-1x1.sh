#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-encode-1x1
# @title: gif2rgb 1x1 RGB roundtrip
# @description: Synthesizes a 3-byte RGB triplet, encodes it into a 1x1 GIF with gif2rgb -s, decodes the GIF back to RGB, and verifies the decoded stream is exactly three bytes wide and tall and that giftext reports a 1x1 logical screen.
# @timeout: 60
# @tags: usage, cli, gif2rgb, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Single magenta pixel: R=200 G=40 B=180.
python3 -c '
import sys
with open(sys.argv[1], "wb") as fh:
    fh.write(bytes([200, 40, 180]))
' "$tmpdir/pixel.rgb"

[[ "$(wc -c <"$tmpdir/pixel.rgb")" -eq 3 ]]

gif2rgb -s 1 1 <"$tmpdir/pixel.rgb" >"$tmpdir/encoded.gif"
file "$tmpdir/encoded.gif" | grep -q 'GIF image data'

giftext "$tmpdir/encoded.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Width = 1, Height = 1'

gif2rgb -1 -o "$tmpdir/decoded.rgb" "$tmpdir/encoded.gif"
[[ "$(wc -c <"$tmpdir/decoded.rgb")" -eq 3 ]]
