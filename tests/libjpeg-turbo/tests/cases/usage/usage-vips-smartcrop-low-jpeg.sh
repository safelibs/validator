#!/usr/bin/env bash
# @testcase: usage-vips-smartcrop-low-jpeg
# @title: vips smartcrop interesting=low JPEG
# @description: Crops a JPEG to a smaller window using vips smartcrop with interesting=low (the least salient region) and verifies the output JPEG has the requested dimensions and JPEG magic.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-smartcrop-low-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 32x32 image with a bright salient blob; smartcrop --interesting=low should
# pick a different region than the default attention mode does.
python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
w, h = 32, 32
pix = bytearray()
for y in range(h):
    for x in range(w):
        dx, dy = x - 8, y - 8
        if dx * dx + dy * dy < 16:
            pix += bytes([240, 240, 240])
        else:
            pix += bytes([60 + (x * 3) % 30, 60 + (y * 3) % 30, 80])
Path(sys.argv[1]).write_bytes(f"P6\n{w} {h}\n255\n".encode() + bytes(pix))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vipsheader "$tmpdir/in.jpg" | tee "$tmpdir/before.out"
validator_assert_contains "$tmpdir/before.out" '32x32'

vips smartcrop "$tmpdir/in.jpg" "$tmpdir/out.jpg" 12 12 --interesting=low
validator_require_file "$tmpdir/out.jpg"

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/after.out"
validator_assert_contains "$tmpdir/after.out" '12x12'

python3 - <<'PY' "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (12, 12), im.size
    print('smartcrop-low', im.size)
PY
