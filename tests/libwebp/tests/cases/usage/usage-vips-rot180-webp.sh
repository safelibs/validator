#!/usr/bin/env bash
# @testcase: usage-vips-rot180-webp
# @title: vips rotates WebP 180 degrees
# @description: Rotates a WebP image by 180 degrees with vips and verifies the output dimensions remain unchanged.
# @timeout: 180
# @tags: usage, webp, image
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-rot180-webp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_webp() {
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
}

make_webp
vips rot "$tmpdir/in.webp" "$tmpdir/out.png" d180
vipsheader "$tmpdir/out.png" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '4x3'
