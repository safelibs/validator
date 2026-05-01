#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-pixdata-name
# @title: gdk-pixbuf WebP pixdata --name C source
# @description: Loads a WebP fixture via gdk-pixbuf-pixdata with --name to emit a C source declaration and verifies the generated text contains the chosen identifier and a GdkPixdata struct.
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

gdk-pixbuf-pixdata --name=validator_webp_blob \
  "$tmpdir/in.webp" "$tmpdir/out.c"
validator_require_file "$tmpdir/out.c"
test "$(wc -c <"$tmpdir/out.c")" -gt 0
validator_assert_contains "$tmpdir/out.c" 'validator_webp_blob'
validator_assert_contains "$tmpdir/out.c" 'GdkPixdata'
