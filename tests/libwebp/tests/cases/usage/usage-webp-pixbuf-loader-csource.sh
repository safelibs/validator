#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-csource
# @title: gdk-pixbuf-csource on WebP
# @description: Generates a C source pixel data array from a WebP fixture via gdk-pixbuf-csource using the WebP pixbuf loader.
# @timeout: 180
# @tags: usage, webp, pixbuf
# @client: webp-pixbuf-loader

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

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
gdk-pixbuf-csource --raw --name=webp_fixture "$tmpdir/in.webp" >"$tmpdir/out.c"
validator_require_file "$tmpdir/out.c"
test "$(wc -c <"$tmpdir/out.c")" -gt 0

# The C source must declare the named pixel-data array and embed the GdkPixdata
# magic ("GdkP", 0x47646b50) plus the source image dimensions (4x3) the WebP
# pixbuf loader decoded.
validator_assert_contains "$tmpdir/out.c" 'webp_fixture[]'
validator_assert_contains "$tmpdir/out.c" 'Pixbuf magic'
validator_assert_contains "$tmpdir/out.c" 'GdkP'
validator_assert_contains "$tmpdir/out.c" 'width (4)'
validator_assert_contains "$tmpdir/out.c" 'height (3)'
