#!/usr/bin/env bash
# @testcase: usage-vips-extract-band-jpeg
# @title: vips extract JPEG band
# @description: Extracts a JPEG color band with vips and verifies the single-band image output.
# @timeout: 180
# @tags: usage, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

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
vips extract_band "$tmpdir/in.jpg" "$tmpdir/band.pgm" 0
validator_require_file "$tmpdir/band.pgm"
vipsheader "$tmpdir/band.pgm" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" '1 band'
