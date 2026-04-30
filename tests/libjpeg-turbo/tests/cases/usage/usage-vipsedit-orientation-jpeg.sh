#!/usr/bin/env bash
# @testcase: usage-vipsedit-orientation-jpeg
# @title: vips rot d90 rotates JPEG by 90 degrees
# @description: Saves a JPEG via cjpeg with non-square dimensions (4x3), runs vips rot d90 to rotate it 90 degrees clockwise, and verifies vipsheader reports swapped dimensions (3x4) on the rotated output while the file remains a valid JPEG.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vipsedit-orientation-jpeg"
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
file "$tmpdir/in.jpg" | tee "$tmpdir/magic"
validator_assert_contains "$tmpdir/magic" 'JPEG image data'

vipsheader -a "$tmpdir/in.jpg" | tee "$tmpdir/in-header"
validator_assert_contains "$tmpdir/in-header" 'width: 4'
validator_assert_contains "$tmpdir/in-header" 'height: 3'

# vips rot d90 rotates the pixel data 90 degrees clockwise; the saved JPEG
# must report swapped width/height.
vips rot "$tmpdir/in.jpg" "$tmpdir/out.jpg" d90

vipsheader -a "$tmpdir/out.jpg" | tee "$tmpdir/out-header"
validator_assert_contains "$tmpdir/out-header" 'width: 3'
validator_assert_contains "$tmpdir/out-header" 'height: 4'

# File magic must still report a JPEG.
file "$tmpdir/out.jpg" | tee "$tmpdir/after-magic"
validator_assert_contains "$tmpdir/after-magic" 'JPEG image data'
