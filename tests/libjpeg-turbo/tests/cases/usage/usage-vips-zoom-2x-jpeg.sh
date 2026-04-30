#!/usr/bin/env bash
# @testcase: usage-vips-zoom-2x-jpeg
# @title: vips zoom 2x JPEG
# @description: Zooms a JPEG by an integer factor of 2 with vips zoom and verifies that the output width and height doubled via vipsheader -a.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-zoom-2x-jpeg"
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
vipsheader -a "$tmpdir/in.jpg" | tee "$tmpdir/in.header"
validator_assert_contains "$tmpdir/in.header" 'width: 16'
validator_assert_contains "$tmpdir/in.header" 'height: 16'

vips zoom "$tmpdir/in.jpg" "$tmpdir/zoom.png" 2 2
validator_require_file "$tmpdir/zoom.png"
vipsheader -a "$tmpdir/zoom.png" | tee "$tmpdir/out.header"
validator_assert_contains "$tmpdir/out.header" 'width: 32'
validator_assert_contains "$tmpdir/out.header" 'height: 32'
