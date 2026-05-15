#!/usr/bin/env bash
# @testcase: usage-vips-r20-extract-area-strip-roundtrip-jpeg
# @title: vips extract_area on a JPEG yields a sub-image of exactly the requested dims
# @description: Encodes a 64x32 PPM to JPEG via vips jpegsave then runs vips extract_area to pull a 20x10 region at offset (5,4), saves it back to JPEG, and asserts vipsheader -f width/height report (20,10), exercising libjpeg-turbo decode followed by vips' bounded sub-region extraction and re-encode.
# @timeout: 180
# @tags: usage, vips, jpeg, extract-area, roundtrip, r20
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

W=64; H=32
{
  printf 'P6\n%d %d\n255\n' "$W" "$H"
  python3 -c "import sys
W, H = $W, $H
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 4) & 255, (y * 8) & 255, ((x + y) * 2) & 255))
sys.stdout.buffer.write(b)
"
} >"$tmpdir/in.ppm"

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/src.jpg"
vips extract_area "$tmpdir/src.jpg" "$tmpdir/sub.jpg" 5 4 20 10

w=$(vipsheader -f width "$tmpdir/sub.jpg")
h=$(vipsheader -f height "$tmpdir/sub.jpg")
[[ "$w" == "20" ]] || { printf 'expected width 20, got %s\n' "$w" >&2; exit 1; }
[[ "$h" == "10" ]] || { printf 'expected height 10, got %s\n' "$h" >&2; exit 1; }
