#!/usr/bin/env bash
# @testcase: usage-python3-pil-imagedraw-roundtrip-jpeg
# @title: Pillow ImageDraw JPEG roundtrip
# @description: Draws a filled rectangle on a JPEG via ImageDraw, saves, and verifies the painted pixel value roundtrips.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$tmpdir"
from pathlib import Path
from PIL import Image, ImageDraw
import sys

tmpdir = Path(sys.argv[1])
base = Image.new('RGB', (32, 32), (10, 20, 30))
src = tmpdir / 'in.jpg'
base.save(src, 'JPEG', quality=95, subsampling=0)

with Image.open(src) as im:
    im.load()
    canvas = im.convert('RGB')

draw = ImageDraw.Draw(canvas)
draw.rectangle((4, 4, 19, 19), fill=(250, 5, 5))

painted = tmpdir / 'painted.jpg'
canvas.save(painted, 'JPEG', quality=95, subsampling=0)

with Image.open(painted) as im:
    im.load()
    assert im.format == 'JPEG'
    assert im.size == (32, 32)
    # Sample center of drawn rectangle; quality=95 + subsampling=0 must keep red dominant.
    r, g, b = im.getpixel((11, 11))
    assert r > 200, f"expected red dominant, got {(r, g, b)}"
    assert g < 60 and b < 60, f"expected suppressed green/blue, got {(r, g, b)}"
    # Sample untouched corner; should still be near the dark teal background.
    r2, g2, b2 = im.getpixel((28, 28))
    assert r2 < 60 and 5 < g2 < 80 and 10 < b2 < 90, f"corner not preserved: {(r2, g2, b2)}"
print('painted', (r, g, b), 'corner', (r2, g2, b2))
PYCASE

file "$tmpdir/painted.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
