#!/usr/bin/env bash
# @testcase: usage-vips-webpsave-preset-text
# @title: vips webpsave preset=text
# @description: Re-encodes a WebP via vips webpsave with preset=text and verifies the output is loaded through webpload at the original dimensions.
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
    0, 0, 0, 255, 255, 255, 0, 0, 0, 255, 255, 255,
    255, 255, 255, 0, 0, 0, 255, 255, 255, 0, 0, 0,
    0, 0, 0, 255, 255, 255, 0, 0, 0, 255, 255, 255,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
vips copy "$tmpdir/in.webp" "$tmpdir/out.webp[preset=text,Q=70]"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

vipsheader -a "$tmpdir/out.webp" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'webpload'
validator_assert_contains "$tmpdir/header" 'width: 4'
validator_assert_contains "$tmpdir/header" 'height: 3'
