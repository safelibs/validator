#!/usr/bin/env bash
# @testcase: usage-vips-bandbool-and-jpeg
# @title: vips bandbool and JPEG
# @description: Reduces a JPEG's RGB bands with vips bandbool boolean :and and verifies the output is a single-band image with matching width and height.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-bandbool-and-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

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

vips bandbool "$tmpdir/in.jpg" "$tmpdir/and.pgm" and
validator_require_file "$tmpdir/and.pgm"
vipsheader -a "$tmpdir/and.pgm" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'width: 16'
validator_assert_contains "$tmpdir/header" 'height: 16'
validator_assert_contains "$tmpdir/header" 'bands: 1'
