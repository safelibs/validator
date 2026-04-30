#!/usr/bin/env bash
# @testcase: usage-vips-vipsheader-format-jpeg
# @title: vipsheader -f single field on JPEG
# @description: Uses vipsheader -f to fetch individual header fields (width, height, bands, vips-loader) from a JPEG one at a time and verifies each matches the expected value with no other output present.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-vipsheader-format-jpeg"
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

# vipsheader -f <field> emits only that field's value with no key prefix.
vipsheader -f width "$tmpdir/in.jpg" >"$tmpdir/width.out"
vipsheader -f height "$tmpdir/in.jpg" >"$tmpdir/height.out"
vipsheader -f bands "$tmpdir/in.jpg" >"$tmpdir/bands.out"
vipsheader -f vips-loader "$tmpdir/in.jpg" >"$tmpdir/loader.out"

# Each output is a single line containing only the value.
[[ "$(cat "$tmpdir/width.out")" == "4" ]] || { echo "width=$(cat "$tmpdir/width.out")" >&2; exit 1; }
[[ "$(cat "$tmpdir/height.out")" == "3" ]] || { echo "height=$(cat "$tmpdir/height.out")" >&2; exit 1; }
[[ "$(cat "$tmpdir/bands.out")" == "3" ]] || { echo "bands=$(cat "$tmpdir/bands.out")" >&2; exit 1; }
[[ "$(cat "$tmpdir/loader.out")" == "jpegload" ]] || { echo "loader=$(cat "$tmpdir/loader.out")" >&2; exit 1; }

# Sanity: vipsheader -f output must not contain the field name as a prefix.
validator_assert_contains "$tmpdir/width.out" '4'
! grep -q 'width:' "$tmpdir/width.out"
! grep -q 'vips-loader:' "$tmpdir/loader.out"

echo "vipsheader-f width=4 height=3 bands=3 loader=jpegload"
