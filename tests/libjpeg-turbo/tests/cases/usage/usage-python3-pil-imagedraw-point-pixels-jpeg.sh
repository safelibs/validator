#!/usr/bin/env bash
# @testcase: usage-python3-pil-imagedraw-point-pixels-jpeg
# @title: Pillow ImageDraw.point individual pixels on JPEG
# @description: Opens a JPEG, plots individual pixels with ImageDraw.point at known coordinates using a distinctive color, saves to JPEG, and verifies that plotted coordinates differ from the surrounding background while unplotted pixels remain near the background.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imagedraw-point-pixels-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageDraw
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'points.jpg'

# Use a 32x32 mid-gray base so JPEG can preserve the high-contrast points reasonably.
Image.new('RGB', (32, 32), (128, 128, 128)).save(source, 'JPEG', quality=100, subsampling=0)

points = [(5, 5), (10, 10), (15, 15), (20, 20), (25, 25)]

with Image.open(source) as im:
    assert im.format == 'JPEG'
    canvas = im.convert('RGB')
    draw = ImageDraw.Draw(canvas)
    draw.point(points, fill=(255, 255, 0))
    canvas.save(output, 'JPEG', quality=100, subsampling=0)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.size == (32, 32)
    # JPEG smears single pixels across the 8x8 DCT block, so just confirm
    # that the plotted regions differ from a clearly-untouched background patch.
    bg = im.getpixel((0, 0))
    assert abs(bg[0] - 128) < 15 and abs(bg[1] - 128) < 15 and abs(bg[2] - 128) < 15, bg
    differs = 0
    for px, py in points:
        r, g, b = im.getpixel((px, py))
        # Expect r and g shifted up versus background (toward yellow), or blue shifted down.
        if r > bg[0] + 5 and g > bg[1] + 5 and b < bg[2] + 5:
            differs += 1
    assert differs >= 3, ('not enough differing points', differs)
    print('points', differs, 'bg', bg)

assert output.read_bytes()[:3] == b'\xff\xd8\xff'
PYCASE

file "$tmpdir/points.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
