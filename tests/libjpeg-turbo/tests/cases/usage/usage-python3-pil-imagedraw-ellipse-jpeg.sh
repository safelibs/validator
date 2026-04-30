#!/usr/bin/env bash
# @testcase: usage-python3-pil-imagedraw-ellipse-jpeg
# @title: Pillow ImageDraw.ellipse on JPEG
# @description: Opens a JPEG, draws a filled ellipse with ImageDraw.ellipse, saves the result back to JPEG, and verifies the ellipse interior is the fill color while a corner outside the ellipse stays near the original background.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imagedraw-ellipse-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageDraw
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'ellipse.jpg'

Image.new('RGB', (32, 32), (128, 128, 128)).save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    canvas = im.copy()
    draw = ImageDraw.Draw(canvas)
    # Ellipse spanning most of canvas, filled red.
    draw.ellipse([(4, 4), (27, 27)], fill=(255, 0, 0))
    canvas.save(output, 'JPEG', quality=95, subsampling=0)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.size == (32, 32)
    # Center is inside the ellipse and should be red-dominant.
    center = im.getpixel((15, 15))
    assert center[0] > center[1] + 50 and center[0] > center[2] + 50, center
    # The exact corner (0,0) is outside the ellipse and should remain near the gray background.
    corner = im.getpixel((0, 0))
    assert abs(corner[0] - corner[1]) < 25 and abs(corner[1] - corner[2]) < 25, corner
    print('ellipse', center, corner)

assert output.read_bytes()[:3] == b'\xff\xd8\xff'
PYCASE

file "$tmpdir/ellipse.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
