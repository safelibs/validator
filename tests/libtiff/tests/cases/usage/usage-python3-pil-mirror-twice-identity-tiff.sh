#!/usr/bin/env bash
# @testcase: usage-python3-pil-mirror-twice-identity-tiff
# @title: Pillow mirror twice identity TIFF
# @description: Mirrors a generated TIFF twice with ImageOps.mirror and verifies the result matches the original pixel-for-pixel before round-tripping.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-mirror-twice-identity-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageChops, ImageOps
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.tiff'
output = tmpdir / 'out.tiff'
base = Image.new('RGB', (4, 3))
base.putdata([
    (10, 20, 30), (40, 50, 60), (70, 80, 90), (100, 110, 120),
    (130, 30, 20), (20, 140, 40), (30, 50, 150), (200, 210, 40),
    (15, 200, 100), (220, 30, 180), (90, 160, 10), (250, 250, 250),
])
base.save(source, 'TIFF')

def round_trip(image):
    image.save(output, 'TIFF')
    with Image.open(output) as written:
        assert written.mode == image.mode
        assert written.size == image.size

with Image.open(source) as opened:
    mirror = ImageOps.mirror(opened)
    first = opened.getpixel((0, 0))
    mirrored_first = mirror.getpixel((0, 0))

    out = ImageOps.mirror(mirror)
    for x in range(opened.size[0]):
        for y in range(opened.size[1]):
            assert out.getpixel((x, y)) == opened.getpixel((x, y))
    round_trip(out)
    print('identity')
PYCASE
