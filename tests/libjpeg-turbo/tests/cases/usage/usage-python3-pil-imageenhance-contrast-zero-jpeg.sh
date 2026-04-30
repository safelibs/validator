#!/usr/bin/env bash
# @testcase: usage-python3-pil-imageenhance-contrast-zero-jpeg
# @title: Pillow ImageEnhance.Contrast factor 0.0 collapses to uniform gray
# @description: Applies ImageEnhance.Contrast(0.0) to a JPEG and verifies the result is a uniform gray image whose mean equals the source mean after a JPEG roundtrip.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imageenhance-contrast-zero-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageEnhance, ImageStat
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
out = tmpdir / 'out.jpg'

# Build a checkerboard of two distinct grays at 16x16 (large enough to avoid subsampling mangling).
base = Image.new('L', (16, 16))
pixels = []
for y in range(16):
    for x in range(16):
        pixels.append(60 if (x + y) % 2 == 0 else 200)
base.putdata(pixels)
base.save(source, 'JPEG', quality=100, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    src_mean = ImageStat.Stat(im).mean[0]
    flat = ImageEnhance.Contrast(im).enhance(0.0)
    assert flat.mode == 'L'
    flat_mean = ImageStat.Stat(flat).mean[0]
    assert abs(flat_mean - src_mean) < 2.0, (flat_mean, src_mean)
    flat_extrema = flat.getextrema()
    # Factor 0.0 should yield a single uniform value (delta == 0) before JPEG roundtrip.
    assert flat_extrema[1] - flat_extrema[0] == 0, flat_extrema
    flat.save(out, 'JPEG', quality=100, subsampling=0)

with Image.open(out) as reopened:
    assert reopened.format == 'JPEG'
    assert reopened.mode == 'L'
    assert reopened.size == (16, 16)
    lo, hi = reopened.getextrema()
    # JPEG roundtrip on a constant image should remain constant.
    assert hi - lo <= 2, (lo, hi)
    print('contrast0', src_mean, flat_extrema, (lo, hi))
PYCASE

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
