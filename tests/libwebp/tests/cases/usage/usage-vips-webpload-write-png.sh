#!/usr/bin/env bash
# @testcase: usage-vips-webpload-write-png
# @title: vips webpload then write to PNG
# @description: Loads a WebP fixture through vips and writes it out as PNG, verifying the PNG file magic, dimensions reported by vipsheader, and that getpoint can read pixels back from the converted file.
# @timeout: 180
# @tags: usage, webp, vips
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    10, 200, 50, 90, 30, 240, 60, 60, 60, 0, 0, 0,
    255, 255, 255, 50, 100, 150, 200, 100, 50, 25, 75, 125,
    1, 200, 1, 200, 1, 200, 1, 200, 1, 200, 1, 200,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"

# vips will pick webpload for input and pngsave for output by extension.
vips copy "$tmpdir/in.webp" "$tmpdir/out.png"
validator_require_file "$tmpdir/out.png"
test "$(wc -c <"$tmpdir/out.png")" -gt 0

file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'
validator_assert_contains "$tmpdir/file" '4 x 3'

vipsheader -a "$tmpdir/out.png" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'pngload'
validator_assert_contains "$tmpdir/header" 'width: 4'
validator_assert_contains "$tmpdir/header" 'height: 3'

vips getpoint "$tmpdir/out.png" 0 0 | tee "$tmpdir/point"
test -s "$tmpdir/point"
