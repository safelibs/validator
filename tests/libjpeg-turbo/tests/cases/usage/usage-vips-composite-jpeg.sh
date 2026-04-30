#!/usr/bin/env bash
# @testcase: usage-vips-composite-jpeg
# @title: vips composite two jpegs
# @description: Composites two JPEG layers with vips composite2 over and verifies the merged JPEG dimensions.
# @timeout: 180
# @tags: usage, jpeg, image
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/base.ppm" "$tmpdir/overlay.ppm"
import sys
from pathlib import Path
w, h = 6, 4
base_pix = bytearray()
over_pix = bytearray()
for y in range(h):
    for x in range(w):
        base_pix += bytes([10, (y * 60) % 256, (x * 40) % 256])
        over_pix += bytes([(x * 40) % 256, (y * 50) % 256, 200])
Path(sys.argv[1]).write_bytes(f"P6\n{w} {h}\n255\n".encode() + bytes(base_pix))
Path(sys.argv[2]).write_bytes(f"P6\n{w} {h}\n255\n".encode() + bytes(over_pix))
PY

cjpeg "$tmpdir/base.ppm" >"$tmpdir/base.jpg"
cjpeg "$tmpdir/overlay.ppm" >"$tmpdir/overlay.jpg"

vips composite2 "$tmpdir/base.jpg" "$tmpdir/overlay.jpg" "$tmpdir/comp.jpg" over
file "$tmpdir/comp.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader "$tmpdir/comp.jpg" | tee "$tmpdir/header.out"
validator_assert_contains "$tmpdir/header.out" '6x4'
