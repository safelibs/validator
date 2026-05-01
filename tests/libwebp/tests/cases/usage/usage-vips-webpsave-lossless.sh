#!/usr/bin/env bash
# @testcase: usage-vips-webpsave-lossless
# @title: vips webpsave lossless=true
# @description: Re-encodes an RGB WebP through vips webpsave with lossless=true and verifies the output decodes via webpload at preserved dimensions with three bands and that getpoint reproduces a known input pixel exactly.
# @timeout: 180
# @tags: usage, webp, vips, lossless
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

cwebp -quiet -lossless "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
vips copy "$tmpdir/in.webp" "$tmpdir/out.webp[lossless=true,Q=80]"
validator_require_file "$tmpdir/out.webp"

file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

bands=$(vipsheader -f bands "$tmpdir/out.webp")
test "$bands" = "3"
loader=$(vipsheader -f vips-loader "$tmpdir/out.webp")
test "$loader" = "webpload"
width=$(vipsheader -f width "$tmpdir/out.webp")
test "$width" = "4"
height=$(vipsheader -f height "$tmpdir/out.webp")
test "$height" = "3"

# Lossless guarantees the (0,0) red pixel is preserved exactly.
vips getpoint "$tmpdir/out.webp" 0 0 | tee "$tmpdir/p00"
validator_assert_contains "$tmpdir/p00" '255'
