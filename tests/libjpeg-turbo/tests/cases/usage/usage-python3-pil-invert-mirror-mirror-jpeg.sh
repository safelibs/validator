#!/usr/bin/env bash
# @testcase: usage-python3-pil-invert-mirror-mirror-jpeg
# @title: Pillow invert mirror lighter JPEG
# @description: Inverts a mirrored JPEG with ImageOps.invert and lighter-merges with the original, verifying the per-channel lighter pixel values before round-tripping.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-invert-mirror-mirror-jpeg"
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

    inverted = ImageOps.invert(mirror)
    out = ImageChops.lighter(opened, inverted)
    inv_first = tuple(255 - channel for channel in mirrored_first)
    expected = tuple(max(left, right) for left, right in zip(first, inv_first))
    assert out.getpixel((0, 0)) == expected
    round_trip(out)
    print(expected)
PYCASE
