#!/usr/bin/env bash
# @testcase: usage-vips-embed-white-bg-jpeg
# @title: vips embed JPEG on white background
# @description: Embeds a JPEG into a larger canvas with a white background via vips embed and verifies the canvas size and the white border pixels.
# @timeout: 180
# @tags: usage, jpeg, image
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-embed-white-bg-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_jpeg() {
  python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120,
    130, 30, 20, 20, 140, 40, 30, 50, 150, 200, 210, 40,
    15, 200, 100, 220, 30, 180, 90, 160, 10, 250, 250, 250,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY
  cjpeg -quality 100 "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
}

make_jpeg
vips embed "$tmpdir/in.jpg" "$tmpdir/out.jpg" 2 2 8 7 --extend white
validator_require_file "$tmpdir/out.jpg"
vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" '8x7'

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

python3 - <<'PY' "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (8, 7), im.size
    # Top-left corner is in the embed border, must be white.
    r, g, b = im.getpixel((0, 0))
    assert r > 240 and g > 240 and b > 240, (r, g, b)
    # Bottom-right corner is also outside the embedded image (image at x in [2,5], y in [2,4]).
    r2, g2, b2 = im.getpixel((7, 6))
    assert r2 > 240 and g2 > 240 and b2 > 240, (r2, g2, b2)
    print('corners', (r, g, b), (r2, g2, b2))
PY
