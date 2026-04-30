#!/usr/bin/env bash
# @testcase: usage-vips-arrayjoin-jpeg
# @title: vips arrayjoin two JPEGs side by side
# @description: Encodes two PPMs as JPEGs via cjpeg, joins them horizontally with vips arrayjoin across=2, writes the joined image as a JPEG, and verifies the joined dimensions equal the sum of the input widths and the original height.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-arrayjoin-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/left.ppm" "$tmpdir/right.ppm"
from pathlib import Path
import sys
# Two 16x16 mid-gray PPMs.
header = b"P6\n16 16\n255\n"
pixels = bytes([128] * (16 * 16 * 3))
Path(sys.argv[1]).write_bytes(header + pixels)
Path(sys.argv[2]).write_bytes(header + pixels)
PY

cjpeg "$tmpdir/left.ppm" >"$tmpdir/left.jpg"
cjpeg "$tmpdir/right.ppm" >"$tmpdir/right.jpg"
file "$tmpdir/left.jpg" | tee "$tmpdir/magic"
validator_assert_contains "$tmpdir/magic" 'JPEG image data'

# arrayjoin with across:2 lays the two tiles side by side.
vips arrayjoin "$tmpdir/left.jpg $tmpdir/right.jpg" "$tmpdir/joined.jpg" --across 2
validator_require_file "$tmpdir/joined.jpg"
file "$tmpdir/joined.jpg" | tee "$tmpdir/joined.magic"
validator_assert_contains "$tmpdir/joined.magic" 'JPEG image data'

vipsheader -a "$tmpdir/joined.jpg" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'width: 32'
validator_assert_contains "$tmpdir/header" 'height: 16'
