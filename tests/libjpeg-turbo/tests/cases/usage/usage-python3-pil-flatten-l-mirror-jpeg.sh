#!/usr/bin/env bash
# @testcase: usage-python3-pil-flatten-l-mirror-jpeg
# @title: Pillow grayscale darker mirror JPEG
# @description: Converts a generated JPEG to L mode and darker-merges with its mirrored copy, verifying the minimum luminance value before round-tripping.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-flatten-l-mirror-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageChops, ImageOps
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.jpg'
output = tmpdir / 'out.jpg'
base = Image.new('RGB', (4, 3))
base.putdata([
    (10, 20, 30), (40, 50, 60), (70, 80, 90), (100, 110, 120),
    (130, 30, 20), (20, 140, 40), (30, 50, 150), (200, 210, 40),
    (15, 200, 100), (220, 30, 180), (90, 160, 10), (250, 250, 250),
])
base.save(source, 'JPEG', quality=100, subsampling=0)

def round_trip(image):
    image.save(output, 'JPEG', quality=100, subsampling=0)
    with Image.open(output) as written:
        assert written.mode == image.mode
        assert written.size == image.size

with Image.open(source) as opened:
    mirror = ImageOps.mirror(opened)
    first = opened.getpixel((0, 0))
    mirrored_first = mirror.getpixel((0, 0))

    gray = opened.convert('L')
    gray_mirror = ImageOps.mirror(gray)
    out = ImageChops.darker(gray, gray_mirror)
    first_l = gray.getpixel((0, 0))
    mirror_l = gray_mirror.getpixel((0, 0))
    assert out.getpixel((0, 0)) == min(first_l, mirror_l)
    out_rgb = out.convert('RGB')
    round_trip(out_rgb)
    print(out.getpixel((0, 0)))
PYCASE
