#!/usr/bin/env bash
# @testcase: usage-vips-reduce-jpeg
# @title: vips reduce jpeg
# @description: Reduces a JPEG by fractional factors via vips reduce and verifies the new dimensions.
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
# 8x6 PPM so reduce 2.0/3.0 yields integer dims.
w, h = 8, 6
pix = bytearray()
for y in range(h):
    for x in range(w):
        pix += bytes([(x * 17) % 256, (y * 23) % 256, ((x + y) * 11) % 256])
Path(sys.argv[1]).write_bytes(f"P6\n{w} {h}\n255\n".encode() + bytes(pix))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vipsheader "$tmpdir/in.jpg" | tee "$tmpdir/before.out"
validator_assert_contains "$tmpdir/before.out" '8x6'

vips reduce "$tmpdir/in.jpg" "$tmpdir/reduced.jpg" 2.0 3.0
file "$tmpdir/reduced.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader "$tmpdir/reduced.jpg" | tee "$tmpdir/after.out"
validator_assert_contains "$tmpdir/after.out" '4x2'
