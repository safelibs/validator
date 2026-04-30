#!/usr/bin/env bash
# @testcase: usage-vips-vipsheader-all-jpeg
# @title: vipsheader all metadata jpeg
# @description: Runs vipsheader -a on a JPEG and asserts core fields width, height, bands, and jpegload loader.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vipsheader -a "$tmpdir/in.jpg" | tee "$tmpdir/header.out"

# Core dimensions/bands and loader identification must be reported.
validator_assert_contains "$tmpdir/header.out" 'width: 4'
validator_assert_contains "$tmpdir/header.out" 'height: 3'
validator_assert_contains "$tmpdir/header.out" 'bands: 3'
validator_assert_contains "$tmpdir/header.out" 'vips-loader: jpegload'
