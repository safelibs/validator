#!/usr/bin/env bash
# @testcase: usage-vips-smartcrop-jpeg
# @title: vips smartcrop JPEG
# @description: Crops a JPEG to a smaller window via vips smartcrop and verifies the output dimensions and JPEG magic.
# @timeout: 180
# @tags: usage, jpeg, image
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
w, h = 32, 32
pix = bytearray()
for y in range(h):
    for x in range(w):
        # Bright spot near center so smartcrop has a salient region.
        dx, dy = x - 20, y - 20
        if dx * dx + dy * dy < 16:
            pix += bytes([240, 240, 240])
        else:
            pix += bytes([60 + (x * 3) % 30, 60 + (y * 3) % 30, 80])
Path(sys.argv[1]).write_bytes(f"P6\n{w} {h}\n255\n".encode() + bytes(pix))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vipsheader "$tmpdir/in.jpg" | tee "$tmpdir/before.out"
validator_assert_contains "$tmpdir/before.out" '32x32'

vips smartcrop "$tmpdir/in.jpg" "$tmpdir/out.jpg" 8 8
file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/after.out"
validator_assert_contains "$tmpdir/after.out" '8x8'
