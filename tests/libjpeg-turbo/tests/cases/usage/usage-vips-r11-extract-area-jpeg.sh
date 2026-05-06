#!/usr/bin/env bash
# @testcase: usage-vips-r11-extract-area-jpeg
# @title: vips extract_area carves a rectangular subregion out of a JPEG
# @description: Loads a JPEG and uses vips extract_area to extract a rectangular subregion at a given offset and size, asserting the resulting JPEG matches the requested width and height via vipsheader.
# @timeout: 60
# @tags: usage, jpeg, image, extract
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 48, 36
data = bytes([(i * 5) & 0xFF for i in range(w * h * 3)])
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 80
vips extract_area "$tmpdir/in.jpg" "$tmpdir/out.jpg" 8 4 24 18

vipsheader -a "$tmpdir/out.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 24'
validator_assert_contains "$tmpdir/hdr" 'height: 18'
file "$tmpdir/out.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
