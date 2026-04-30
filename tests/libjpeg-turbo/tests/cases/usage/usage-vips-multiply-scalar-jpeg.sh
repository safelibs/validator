#!/usr/bin/env bash
# @testcase: usage-vips-multiply-scalar-jpeg
# @title: vips linear multiply scalar JPEG
# @description: Multiplies a JPEG by a positive scalar constant via vips linear (the supported way to do scalar multiplication; math2_const has no multiply member), writes the result as a JPEG, and verifies the output dimensions and per-pixel values approximately equal the input scaled by the scalar.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-multiply-scalar-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 16x16 mid-gray (vips linear / multiply rejects negative scalars and yields
# all-black output if the input is already black; mid-gray gives clean results).
python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
header = b"P6\n16 16\n255\n"
pixels = bytes([100] * (16 * 16 * 3))
Path(sys.argv[1]).write_bytes(header + pixels)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
file "$tmpdir/in.jpg" | tee "$tmpdir/magic"
validator_assert_contains "$tmpdir/magic" 'JPEG image data'

# linear computes (a * x + b); with a=2 and b=0 every pixel is scaled by 2
# across all bands. (vips math2_const does not implement a multiply member.)
vips linear "$tmpdir/in.jpg" "$tmpdir/out.jpg" 2 0
validator_require_file "$tmpdir/out.jpg"

vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" '16x16'

file "$tmpdir/out.jpg" | tee "$tmpdir/out-magic"
validator_assert_contains "$tmpdir/out-magic" 'JPEG image data'

python3 - <<'PY' "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (16, 16)
    r, g, b = im.getpixel((8, 8))
    # Input pixel was (100,100,100); 100*2 = 200 (clipped well below 255).
    for ch in (r, g, b):
        assert abs(ch - 200) < 12, (r, g, b)
    print('multiply-scalar', (r, g, b))
PY
