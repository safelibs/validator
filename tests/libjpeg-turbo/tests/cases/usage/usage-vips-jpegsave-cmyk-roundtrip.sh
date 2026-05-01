#!/usr/bin/env bash
# @testcase: usage-vips-jpegsave-cmyk-roundtrip
# @title: vips CMYK JPEG roundtrip
# @description: Converts an RGB JPEG to CMYK via vips colourspace, saves it as a 4-channel JPEG, and verifies vipsheader reports 4 bands cmyk after reload — exercising libjpeg-turbo's CMYK encode/decode paths.
# @timeout: 180
# @tags: usage, jpeg, image, color
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
W, H = 48, 32
pixels = bytearray()
for y in range(H):
    for x in range(W):
        pixels += bytes((((x * 11) ^ (y * 7)) & 255, (x * 5) & 255, (y * 9) & 255))
Path(sys.argv[1]).write_bytes(f"P6\n{W} {H}\n255\n".encode() + bytes(pixels))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vips colourspace "$tmpdir/in.jpg" "$tmpdir/cmyk.jpg" cmyk
file "$tmpdir/cmyk.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
validator_assert_contains "$tmpdir/file.out" 'components 4'

vipsheader "$tmpdir/cmyk.jpg" | tee "$tmpdir/header.out"
validator_assert_contains "$tmpdir/header.out" '4 bands'
validator_assert_contains "$tmpdir/header.out" 'cmyk'

# Round-trip back to sRGB and confirm vips reads the CMYK JPEG without errors.
vips colourspace "$tmpdir/cmyk.jpg" "$tmpdir/back.jpg" srgb
vipsheader "$tmpdir/back.jpg" | tee "$tmpdir/back.out"
validator_assert_contains "$tmpdir/back.out" '3 bands'
validator_assert_contains "$tmpdir/back.out" 'srgb'
