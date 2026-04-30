#!/usr/bin/env bash
# @testcase: usage-vips-relational-const-threshold-jpeg
# @title: vips relational_const less threshold on JPEG
# @description: Encodes a mid-gray PPM as JPEG via cjpeg, applies vips relational_const with the less operator and a threshold of 200 to produce a uchar mask that is 255 wherever the pixel value is below 200, and verifies the mask has matching dimensions and the expected band count.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-relational-const-threshold-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
# 16x16 mid-gray PPM (value 128 in all channels).
header = b"P6\n16 16\n255\n"
pixels = bytes([128] * (16 * 16 * 3))
Path(sys.argv[1]).write_bytes(header + pixels)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
file "$tmpdir/in.jpg" | tee "$tmpdir/magic"
validator_assert_contains "$tmpdir/magic" 'JPEG image data'

# All pixels are ~128 < 200, so the less-than mask should be all-true (255 across all 3 bands).
vips relational_const "$tmpdir/in.jpg" "$tmpdir/mask.png" less 200
validator_require_file "$tmpdir/mask.png"
file "$tmpdir/mask.png" | tee "$tmpdir/mask.magic"
validator_assert_contains "$tmpdir/mask.magic" 'PNG image data'

vipsheader -a "$tmpdir/mask.png" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'width: 16'
validator_assert_contains "$tmpdir/header" 'height: 16'
validator_assert_contains "$tmpdir/header" 'bands: 3'

# Sample a single pixel via vips getpoint and confirm the mask is true (255) there.
vips getpoint "$tmpdir/mask.png" 8 8 | tee "$tmpdir/point"
validator_assert_contains "$tmpdir/point" '255'
