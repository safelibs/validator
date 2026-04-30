#!/usr/bin/env bash
# @testcase: usage-vips-reducev-jpeg
# @title: vips reducev JPEG vertical-only reduction
# @description: Reduces a JPEG vertically only via vips reducev and verifies the height shrinks while the width is unchanged.
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
w, h = 8, 12
pix = bytearray()
for y in range(h):
    for x in range(w):
        pix += bytes([(x * 19) % 256, (y * 29) % 256, ((x + y) * 13) % 256])
Path(sys.argv[1]).write_bytes(f"P6\n{w} {h}\n255\n".encode() + bytes(pix))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vipsheader "$tmpdir/in.jpg" | tee "$tmpdir/before.out"
validator_assert_contains "$tmpdir/before.out" '8x12'

vips reducev "$tmpdir/in.jpg" "$tmpdir/out.jpg" 4.0
file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/after.out"
validator_assert_contains "$tmpdir/after.out" '8x3'
