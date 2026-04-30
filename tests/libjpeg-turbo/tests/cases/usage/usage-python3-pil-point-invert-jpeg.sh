#!/usr/bin/env bash
# @testcase: usage-python3-pil-point-invert-jpeg
# @title: Pillow Image.point lambda 255-x JPEG
# @description: Applies Image.point with a 255-x lookup to invert a JPEG and verifies pixel values match the manual inversion.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-point-invert-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'out.jpg'

Image.new('RGB', (8, 6), (60, 120, 200)).save(source, 'JPEG', quality=100, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    inverted = im.point(lambda x: 255 - x)
    inverted.save(output, 'JPEG', quality=100, subsampling=0)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (8, 6)
    r, g, b = im.getpixel((4, 3))
    # Invert of (60, 120, 200) is (195, 135, 55).
    assert abs(r - 195) < 8, (r, g, b)
    assert abs(g - 135) < 8, (r, g, b)
    assert abs(b - 55) < 8, (r, g, b)
    print('point invert', (r, g, b))
PYCASE

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
