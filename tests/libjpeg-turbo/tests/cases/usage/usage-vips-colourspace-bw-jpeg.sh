#!/usr/bin/env bash
# @testcase: usage-vips-colourspace-bw-jpeg
# @title: vips colourspace b-w JPEG
# @description: Converts an RGB JPEG to grayscale via vips colourspace b-w and verifies the output is a single-band JPEG.
# @timeout: 180
# @tags: usage, jpeg, image
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-colourspace-bw-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_jpeg() {
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
  cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
}

make_jpeg
vips colourspace "$tmpdir/in.jpg" "$tmpdir/out.jpg" b-w
validator_require_file "$tmpdir/out.jpg"
vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" '4x3'
validator_assert_contains "$tmpdir/header" '1 band'

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

python3 - <<'PY' "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'L', im.mode
    assert im.size == (4, 3)
    print('grayscale', im.mode, im.size)
PY
