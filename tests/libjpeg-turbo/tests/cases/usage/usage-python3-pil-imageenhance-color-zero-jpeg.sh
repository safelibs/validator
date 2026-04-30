#!/usr/bin/env bash
# @testcase: usage-python3-pil-imageenhance-color-zero-jpeg
# @title: Pillow ImageEnhance.Color factor 0.0 yields grayscale
# @description: Applies ImageEnhance.Color(0.0) to an RGB JPEG and verifies all three channels collapse to the same per-pixel luminance, surviving a JPEG roundtrip.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imageenhance-color-zero-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageEnhance
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
out = tmpdir / 'out.jpg'

# 16x16 with mid-range RGB pattern keeps chroma subsampling non-destructive.
img = Image.new('RGB', (16, 16))
pixels = []
for y in range(16):
    for x in range(16):
        pixels.append((120 + x * 4, 130 + y * 3, 140))
img.putdata(pixels)
img.save(source, 'JPEG', quality=100, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    desat = ImageEnhance.Color(im).enhance(0.0)
    assert desat.mode == 'RGB'
    # Pre-roundtrip: every pixel must have R == G == B.
    for px in desat.getdata():
        r, g, b = px
        assert r == g == b, px
    desat.save(out, 'JPEG', quality=100, subsampling=0)

with Image.open(out) as reopened:
    assert reopened.format == 'JPEG'
    assert reopened.mode == 'RGB'
    assert reopened.size == (16, 16)
    deltas = []
    for px in reopened.getdata():
        r, g, b = px
        deltas.append(max(abs(r - g), abs(g - b), abs(r - b)))
    assert max(deltas) <= 4, max(deltas)
    print('color0', reopened.size, max(deltas))
PYCASE

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
