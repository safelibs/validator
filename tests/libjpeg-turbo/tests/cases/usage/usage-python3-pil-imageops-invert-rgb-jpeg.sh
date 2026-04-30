#!/usr/bin/env bash
# @testcase: usage-python3-pil-imageops-invert-rgb-jpeg
# @title: Pillow ImageOps.invert RGB JPEG
# @description: Applies ImageOps.invert to an RGB JPEG and verifies a representative pixel inverts via 255 minus channel.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imageops-invert-rgb-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageOps
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'out.jpg'

Image.new('RGB', (8, 6), (40, 200, 90)).save(source, 'JPEG', quality=100, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    inverted = ImageOps.invert(im)
    inverted.save(output, 'JPEG', quality=100, subsampling=0)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (8, 6)
    r, g, b = im.getpixel((4, 3))
    # Inverted of (40, 200, 90) is (215, 55, 165). JPEG quantization at q=100 stays close.
    assert abs(r - 215) < 8, (r, g, b)
    assert abs(g - 55) < 8, (r, g, b)
    assert abs(b - 165) < 8, (r, g, b)
    print('inverted', (r, g, b))
PYCASE

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
