#!/usr/bin/env bash
# @testcase: usage-vips-invert-jpeg
# @title: vips inverts JPEG
# @description: Inverts a JPEG with vips invert and verifies the output dimensions, file magic, and a representative pixel via Pillow.
# @timeout: 180
# @tags: usage, jpeg, image
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-invert-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Generate a 32x32 uniform-block PPM so JPEG chroma subsampling cannot
# pull corner pixels away from their nominal value, then encode at quality
# 100 to keep the round-trip tight.
python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys

W, H = 32, 32
# Solid mid-gray (#404040) makes the invert math (vips invert is "255 - x"
# for each uchar band) trivial to verify regardless of YCbCr conversion.
pixels = bytes([0x40, 0x40, 0x40] * (W * H))
Path(sys.argv[1]).write_bytes(f"P6\n{W} {H}\n255\n".encode() + pixels)
PY
cjpeg -quality 100 "$tmpdir/in.ppm" >"$tmpdir/in.jpg"

vips invert "$tmpdir/in.jpg" "$tmpdir/out.jpg"
validator_require_file "$tmpdir/out.jpg"
vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" '32x32'

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys

with Image.open(sys.argv[1]) as src, Image.open(sys.argv[2]) as inv:
    assert src.format == 'JPEG' and inv.format == 'JPEG'
    assert src.mode == 'RGB' and inv.mode == 'RGB'
    assert src.size == inv.size == (32, 32)
    # Sample the centre of the image where JPEG block boundaries are not in
    # play, so the invert relationship is observable.
    sx = src.convert('RGB').getpixel((16, 16))
    ix = inv.convert('RGB').getpixel((16, 16))
    for s, i in zip(sx, ix):
        assert abs((255 - s) - i) <= 6, (sx, ix)
    # The inverted block must also be lighter on average than the dark-grey
    # source, confirming the operation was applied.
    assert sum(ix) > sum(sx), (sx, ix)
    print('src', sx, 'inv', ix)
PY
