#!/usr/bin/env bash
# @testcase: usage-vips-jpeg-to-tiff
# @title: vips JPEG to TIFF
# @description: Copies JPEG input to TIFF with vips and verifies TIFF output is produced.
# @timeout: 180
# @tags: usage, jpeg, image
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-jpeg-to-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_jpeg() {
  python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY
  cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
}

make_jpeg
vips copy "$tmpdir/in.jpg" "$tmpdir/out.tif"
file "$tmpdir/out.tif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'TIFF image data'
