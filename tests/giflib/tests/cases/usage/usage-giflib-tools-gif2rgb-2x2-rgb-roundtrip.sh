#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-2x2-rgb-roundtrip
# @title: gif2rgb 2x2 four-pixel RGB roundtrip
# @description: Synthesizes a deterministic 12-byte RGB stream representing four distinct pixels, encodes it into a 2x2 GIF with gif2rgb -s 2 2, decodes the GIF back to RGB with gif2rgb -1, and verifies the decoded stream is exactly 12 bytes and that giftext reports a 2x2 logical screen for the encoded GIF.
# @timeout: 60
# @tags: usage, cli, gif2rgb, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Four corner pixels: red, green, blue, white.
python3 -c '
import sys
data = bytes([
    255,   0,   0,
      0, 255,   0,
      0,   0, 255,
    255, 255, 255,
])
with open(sys.argv[1], "wb") as fh:
    fh.write(data)
' "$tmpdir/pixels.rgb"

[[ "$(wc -c <"$tmpdir/pixels.rgb")" -eq 12 ]]

gif2rgb -s 2 2 <"$tmpdir/pixels.rgb" >"$tmpdir/encoded.gif"
file "$tmpdir/encoded.gif" | grep -q 'GIF image data'

giftext "$tmpdir/encoded.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Width = 2, Height = 2'

gif2rgb -1 -o "$tmpdir/decoded.rgb" "$tmpdir/encoded.gif"
decoded_bytes=$(wc -c <"$tmpdir/decoded.rgb")
[[ "$decoded_bytes" -eq 12 ]] || {
  printf 'expected 12 decoded bytes, got %d\n' "$decoded_bytes" >&2
  exit 1
}

# gif2rgb encodes via a quantized palette so the bytes need not match exactly,
# but the byte count must be an exact 2*2*3 = 12 frame.
