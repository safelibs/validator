#!/usr/bin/env bash
# @testcase: usage-vips-gravity-centre-jpeg
# @title: vips gravity centre JPEG placement
# @description: Places a small JPEG into a larger canvas using vips gravity with direction "centre" and verifies the resulting image dimensions match the requested canvas size.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-gravity-centre-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Mid-gray 16x16 input so vips has data to place; gravity preserves pixel values
# inside the placed region and pads the rest with the default extend mode.
python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
header = b"P6\n16 16\n255\n"
pixels = bytes([128] * (16 * 16 * 3))
Path(sys.argv[1]).write_bytes(header + pixels)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
file "$tmpdir/in.jpg" | tee "$tmpdir/magic"
validator_assert_contains "$tmpdir/magic" 'JPEG image data'

# Place the 16x16 image centred inside a 32x24 canvas.
vips gravity "$tmpdir/in.jpg" "$tmpdir/out.png" centre 32 24
validator_require_file "$tmpdir/out.png"

vipsheader "$tmpdir/out.png" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" '32x24'

python3 - <<'PY' "$tmpdir/out.png"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.size == (32, 24), im.size
    # The centre pixel should fall inside the placed region (mid-gray).
    px = im.getpixel((16, 12))
    if isinstance(px, int):
        px = (px, px, px)
    r, g, b = px[:3]
    for ch in (r, g, b):
        assert abs(ch - 128) < 12, (r, g, b)
    print('gravity-centre', im.size, (r, g, b))
PY
