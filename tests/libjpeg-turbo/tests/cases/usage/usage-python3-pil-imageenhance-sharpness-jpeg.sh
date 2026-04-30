#!/usr/bin/env bash
# @testcase: usage-python3-pil-imageenhance-sharpness-jpeg
# @title: Pillow ImageEnhance.Sharpness JPEG roundtrip
# @description: Applies ImageEnhance.Sharpness with identity, blur, and sharpen factors to a JPEG and verifies that 1.0 is closest to the source while 0.0 and 2.0 each diverge in opposing directions, surviving a JPEG roundtrip.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imageenhance-sharpness-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageEnhance, ImageChops
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
identity = tmpdir / 'identity.jpg'
blurred = tmpdir / 'blurred.jpg'
sharpened = tmpdir / 'sharpened.jpg'

# 32x32 vertical edge so sharpness changes are measurable.
img = Image.new('L', (32, 32))
pixels = [40 if x < 16 else 200 for y in range(32) for x in range(32)]
img.putdata(pixels)
img.save(source, 'JPEG', quality=100, subsampling=0)

def diff_sum(a, b):
    return sum(ImageChops.difference(a.convert('L'), b.convert('L')).getdata())

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.size == (32, 32)
    base = im.convert('L').copy()
    enhancer = ImageEnhance.Sharpness(im)
    img_id = enhancer.enhance(1.0)
    img_bl = enhancer.enhance(0.0)
    img_sh = enhancer.enhance(2.0)

# Pre-roundtrip invariants: identity equals source, blur and sharpen each diverge,
# and the divergences are in opposite directions (so 0-vs-2 == 0-vs-1 + 1-vs-2).
d_src_id = diff_sum(base, img_id.convert('L'))
d_src_bl = diff_sum(base, img_bl.convert('L'))
d_src_sh = diff_sum(base, img_sh.convert('L'))
d_bl_sh = diff_sum(img_bl.convert('L'), img_sh.convert('L'))
assert d_src_id == 0, d_src_id
assert d_src_bl > 0, d_src_bl
assert d_src_sh > 0, d_src_sh
assert d_bl_sh == d_src_bl + d_src_sh, (d_bl_sh, d_src_bl, d_src_sh)

img_id.save(identity, 'JPEG', quality=100, subsampling=0)
img_bl.save(blurred, 'JPEG', quality=100, subsampling=0)
img_sh.save(sharpened, 'JPEG', quality=100, subsampling=0)

# Roundtrip survives.
for path in (identity, blurred, sharpened):
    with Image.open(path) as r:
        assert r.format == 'JPEG'
        assert r.size == (32, 32)
        assert r.mode in ('L', 'RGB'), r.mode

print('sharpness', d_src_bl, d_src_sh, d_bl_sh)
PYCASE

file "$tmpdir/sharpened.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
