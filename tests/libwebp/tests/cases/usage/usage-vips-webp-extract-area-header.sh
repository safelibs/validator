#!/usr/bin/env bash
# @testcase: usage-vips-webp-extract-area-header
# @title: vips WebP extract_area header
# @description: Extracts a 3x2 area from a WebP fixture with vips and verifies vipsheader reports the cropped dimensions on the resulting PNG.
# @timeout: 120
# @tags: usage
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-webp-extract-area-header"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_ppm() {
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
}

make_webp() {
  make_ppm
  cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
}

make_webp
vips extract_area "$tmpdir/in.webp" "$tmpdir/area.png" 0 0 3 2
vipsheader "$tmpdir/area.png" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '3x2'
