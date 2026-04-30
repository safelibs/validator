#!/usr/bin/env bash
# @testcase: usage-vips-webpsave-q-100-maximum
# @title: vips webpsave maximum Q=100
# @description: Re-encodes a WebP through vips webpsave with Q=100 (maximum quality) and verifies the output is a WebP with preserved dimensions and a decodable sample pixel.
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
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
vips copy "$tmpdir/in.webp" "$tmpdir/out.webp[Q=100]"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

vipsheader -a "$tmpdir/out.webp" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'webpload'
validator_assert_contains "$tmpdir/header" 'width: 4'
validator_assert_contains "$tmpdir/header" 'height: 3'

vips getpoint "$tmpdir/out.webp" 1 1 | tee "$tmpdir/point"
test -s "$tmpdir/point"
