#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-tiff-crop-region-changes-size
# @title: Pillow crop on a TIFF reload shrinks dimensions to the requested rect
# @description: Saves a 10x10 RGB TIFF via Pillow, reopens, calls .crop((2, 3, 7, 9)), asserts the cropped image has size (5, 6) (width=7-2, height=9-3), and asserts crop().getpixel((0, 0)) equals the parent's getpixel((2, 3)), confirming libtiff-decoded pixel data correctly anchors a PIL crop region.
# @timeout: 60
# @tags: usage, tiff, python, crop, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/crop.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

im = Image.new('RGB', (10, 10))
for y in range(10):
    for x in range(10):
        im.putpixel((x, y), (x * 20 % 255, y * 20 % 255, 50))
im.save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as r:
    r.load()
    parent_p = r.getpixel((2, 3))
    c = r.crop((2, 3, 7, 9))
    assert c.size == (5, 6), c.size
    cp = c.getpixel((0, 0))
    assert cp == parent_p, (cp, parent_p)
    print('ok crop size=%s pixel=%s' % (c.size, cp))
PY
