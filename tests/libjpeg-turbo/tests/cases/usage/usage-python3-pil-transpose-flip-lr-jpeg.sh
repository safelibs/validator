#!/usr/bin/env bash
# @testcase: usage-python3-pil-transpose-flip-lr-jpeg
# @title: Pillow transpose FLIP_LEFT_RIGHT JPEG
# @description: Applies Image.transpose(FLIP_LEFT_RIGHT) on a JPEG-loaded image, round-trips the result through JPEG, and verifies horizontal pixel mirroring on a mid-gray asymmetric stripe.
# @timeout: 120
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-transpose-flip-lr-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.jpg'
flipped = tmpdir / 'flipped.jpg'

# 16x16 mid-gray with asymmetric left/right halves to make flipping observable.
base = Image.new('RGB', (16, 16), (128, 128, 128))
for y in range(16):
    for x in range(16):
        if x < 8:
            base.putpixel((x, y), (128, 128, 128))
        else:
            base.putpixel((x, y), (160, 160, 160))
base.save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.size == (16, 16)
    out = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    out.save(flipped, 'JPEG', quality=95, subsampling=0)

with Image.open(flipped) as im2:
    assert im2.format == 'JPEG'
    assert im2.size == (16, 16)
    # left side should now be brighter than right side after flip
    left = im2.getpixel((2, 8))
    right = im2.getpixel((13, 8))
    assert left[0] > right[0] + 10, (left, right)
    print('flip-lr', left, right)

# magic check
assert flipped.read_bytes()[:3] == b'\xff\xd8\xff'
PYCASE
