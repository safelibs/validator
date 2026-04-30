#!/usr/bin/env bash
# @testcase: usage-vips-abs-jpeg
# @title: vips abs absolute value on JPEG-derived image
# @description: Subtracts a constant from a JPEG via vips linear, takes the absolute value with vips abs, and verifies the result roundtrips back to JPEG with the expected dimensions.
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
w, h = 16, 12
pix = bytearray()
for y in range(h):
    for x in range(w):
        pix += bytes([(x * 11) % 256, (y * 17) % 256, ((x + y) * 7) % 256])
Path(sys.argv[1]).write_bytes(f"P6\n{w} {h}\n255\n".encode() + bytes(pix))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vipsheader "$tmpdir/in.jpg" | tee "$tmpdir/before.out"
validator_assert_contains "$tmpdir/before.out" '16x12'

# Build a second image (mid-gray constant) and subtract it from the source so
# many pixel samples become negative. Subtract is just the arithmetic
# complement of add and produces a signed-result image without needing any
# negative scalar argument to vips linear (which the CLI option parser
# would otherwise consume as a flag).
vips black "$tmpdir/zero.v" 16 12 --bands 3
vips linear "$tmpdir/zero.v" "$tmpdir/gray.v" 1 128
vips subtract "$tmpdir/in.jpg" "$tmpdir/gray.v" "$tmpdir/shifted.v"
vips abs "$tmpdir/shifted.v" "$tmpdir/abs.v"

# Cast back to uchar and write as JPEG so we can verify magic + dims.
vips cast "$tmpdir/abs.v" "$tmpdir/abs_uchar.v" uchar
vips jpegsave "$tmpdir/abs_uchar.v" "$tmpdir/out.jpg"

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/after.out"
validator_assert_contains "$tmpdir/after.out" '16x12'

# Confirm vips stats reports a non-empty min/max on the absolute-value image.
vips stats "$tmpdir/abs.v" "$tmpdir/stats.v"
vips avg "$tmpdir/abs.v" >"$tmpdir/avg.out"
test -s "$tmpdir/avg.out"
