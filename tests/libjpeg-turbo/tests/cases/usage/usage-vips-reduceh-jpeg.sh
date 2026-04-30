#!/usr/bin/env bash
# @testcase: usage-vips-reduceh-jpeg
# @title: vips reduceh JPEG horizontal-only reduction
# @description: Reduces a JPEG horizontally only via vips reduceh and verifies the width shrinks while the height is unchanged.
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
w, h = 12, 8
pix = bytearray()
for y in range(h):
    for x in range(w):
        pix += bytes([(x * 19) % 256, (y * 29) % 256, ((x + y) * 13) % 256])
Path(sys.argv[1]).write_bytes(f"P6\n{w} {h}\n255\n".encode() + bytes(pix))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vipsheader "$tmpdir/in.jpg" | tee "$tmpdir/before.out"
validator_assert_contains "$tmpdir/before.out" '12x8'

vips reduceh "$tmpdir/in.jpg" "$tmpdir/out.jpg" 3.0
file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/after.out"
validator_assert_contains "$tmpdir/after.out" '4x8'
