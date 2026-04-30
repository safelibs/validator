#!/usr/bin/env bash
# @testcase: usage-python3-pil-imagedraw-line-jpeg
# @title: Pillow ImageDraw line on JPEG
# @description: Opens a JPEG, draws a colored line with ImageDraw.line, saves back to JPEG, and verifies dimensions, format, and that pixels along the line differ from the surrounding background.
# @timeout: 120
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imagedraw-line-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageDraw
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.jpg'
output = tmpdir / 'lined.jpg'

Image.new('RGB', (32, 32), (128, 128, 128)).save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.size == (32, 32)
    canvas = im.copy()
    draw = ImageDraw.Draw(canvas)
    draw.line([(2, 16), (29, 16)], fill=(255, 0, 0), width=3)
    canvas.save(output, 'JPEG', quality=95, subsampling=0)

with Image.open(output) as result:
    assert result.format == 'JPEG'
    assert result.size == (32, 32)
    assert result.mode == 'RGB'
    # along the line, red channel should dominate; background ~ gray
    on_line = result.getpixel((15, 16))
    bg = result.getpixel((15, 2))
    assert on_line[0] > on_line[1] + 30 and on_line[0] > on_line[2] + 30, on_line
    assert abs(bg[0] - bg[1]) < 25 and abs(bg[1] - bg[2]) < 25, bg
    print('line', on_line, bg)

assert output.read_bytes()[:3] == b'\xff\xd8\xff'
PYCASE
