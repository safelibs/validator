#!/usr/bin/env bash
# @testcase: usage-python3-pil-difference-zero-jpeg
# @title: Pillow ImageChops difference between identical JPEGs
# @description: Saves a JPEG twice with identical settings and verifies ImageChops.difference yields an all-zero image (extrema (0,0) per band).
# @timeout: 120
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-difference-zero-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageChops
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
a = tmpdir / 'a.jpg'
b = tmpdir / 'b.jpg'
src = Image.new('RGB', (16, 16), (128, 128, 128))
src.save(a, 'JPEG', quality=90, subsampling=0)
src.save(b, 'JPEG', quality=90, subsampling=0)

# file magic check
magic = a.read_bytes()[:3]
assert magic == b'\xff\xd8\xff', magic.hex()

with Image.open(a) as im_a, Image.open(b) as im_b:
    assert im_a.size == im_b.size == (16, 16)
    assert im_a.mode == im_b.mode == 'RGB'
    diff = ImageChops.difference(im_a, im_b)
    extrema = diff.getextrema()
    # expect ((0,0),(0,0),(0,0)) for identical JPEGs
    for lo, hi in extrema:
        assert lo == 0 and hi == 0, extrema
    print('difference-zero', extrema)
PYCASE
