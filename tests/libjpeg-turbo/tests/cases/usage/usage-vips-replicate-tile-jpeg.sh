#!/usr/bin/env bash
# @testcase: usage-vips-replicate-tile-jpeg
# @title: vips replicate tiles JPEG
# @description: Replicates a JPEG into a 2x3 tile grid with vips and verifies the output dimensions via vipsheader -a.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-replicate-tile-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
# 16x16 mid-gray PPM
header = b"P6\n16 16\n255\n"
pixels = bytes([128] * (16 * 16 * 3))
Path(sys.argv[1]).write_bytes(header + pixels)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
file "$tmpdir/in.jpg" | tee "$tmpdir/magic"
validator_assert_contains "$tmpdir/magic" 'JPEG image data'

vips replicate "$tmpdir/in.jpg" "$tmpdir/tiled.png" 2 3
validator_require_file "$tmpdir/tiled.png"
vipsheader -a "$tmpdir/tiled.png" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'width: 32'
validator_assert_contains "$tmpdir/header" 'height: 48'
