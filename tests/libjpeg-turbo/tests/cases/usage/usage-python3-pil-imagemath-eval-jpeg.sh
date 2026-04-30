#!/usr/bin/env bash
# @testcase: usage-python3-pil-imagemath-eval-jpeg
# @title: Pillow ImageMath.eval expression on JPEG
# @description: Loads a JPEG, splits its R and G bands, evaluates a per-pixel expression with ImageMath.eval, and verifies the resulting band roundtrips through JPEG.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imagemath-eval-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageMath
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
out = tmpdir / 'out.jpg'

# Use a mid-gray-ish base so chroma subsampling cannot mangle small color images.
Image.new('RGB', (16, 16), (140, 140, 140)).save(source, 'JPEG', quality=100, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    r, g, b = im.split()
    expr = ImageMath.eval('convert(min((r + g) / 2 + 30, 255), "L")', r=r, g=g)
    assert expr.mode == 'L'
    assert expr.size == (16, 16)
    px = expr.getpixel((0, 0))
    assert 165 <= px <= 175, px
    expr.save(out, 'JPEG', quality=100, subsampling=0)

with Image.open(out) as reopened:
    assert reopened.format == 'JPEG'
    assert reopened.mode == 'L'
    assert reopened.size == (16, 16)
    px = reopened.getpixel((8, 8))
    assert 160 <= px <= 180, px
    print('imagemath', reopened.size, reopened.mode, px)
PYCASE

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
