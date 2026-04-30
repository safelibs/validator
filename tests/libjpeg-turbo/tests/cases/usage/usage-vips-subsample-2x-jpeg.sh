#!/usr/bin/env bash
# @testcase: usage-vips-subsample-2x-jpeg
# @title: vips subsample 2x JPEG
# @description: Subsamples a JPEG by integer factors of 2 in x and y via vips subsample and verifies the output halves the dimensions reported by vipsheader -a.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-subsample-2x-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
# 32x32 mid-gray to keep dimensions safe and chroma stable
header = b"P6\n32 32\n255\n"
pixels = bytes([128] * (32 * 32 * 3))
Path(sys.argv[1]).write_bytes(header + pixels)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
file "$tmpdir/in.jpg" | tee "$tmpdir/magic"
validator_assert_contains "$tmpdir/magic" 'JPEG image data'

vips subsample "$tmpdir/in.jpg" "$tmpdir/sub.png" 2 2
validator_require_file "$tmpdir/sub.png"
vipsheader -a "$tmpdir/sub.png" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'width: 16'
validator_assert_contains "$tmpdir/header" 'height: 16'
