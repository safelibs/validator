#!/usr/bin/env bash
# @testcase: usage-python3-pil-imagedraw-rectangle-outline-fill-jpeg
# @title: Pillow ImageDraw.rectangle outline and fill on JPEG
# @description: Opens a JPEG, draws a rectangle with both outline and fill colors via ImageDraw.rectangle, saves the result back to JPEG, and verifies an interior pixel matches the fill color and an edge pixel matches the outline color.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imagedraw-rectangle-outline-fill-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageDraw
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'rect.jpg'

Image.new('RGB', (32, 32), (128, 128, 128)).save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    canvas = im.copy()
    draw = ImageDraw.Draw(canvas)
    # Rectangle from (8,8) to (23,23): outline blue, fill green.
    draw.rectangle([(8, 8), (23, 23)], outline=(0, 0, 255), fill=(0, 255, 0), width=2)
    canvas.save(output, 'JPEG', quality=95, subsampling=0)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.size == (32, 32)
    # Interior pixel near center should be predominantly green from fill.
    interior = im.getpixel((15, 15))
    assert interior[1] > interior[0] + 30 and interior[1] > interior[2] + 30, interior
    # Edge of the rectangle should be predominantly blue from outline.
    edge = im.getpixel((8, 15))
    assert edge[2] > edge[0] + 30 and edge[2] > edge[1] + 30, edge
    # Background outside rectangle stays near gray.
    bg = im.getpixel((2, 2))
    assert abs(bg[0] - bg[1]) < 25 and abs(bg[1] - bg[2]) < 25, bg
    print('rect', interior, edge, bg)

assert output.read_bytes()[:3] == b'\xff\xd8\xff'
PYCASE

file "$tmpdir/rect.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
