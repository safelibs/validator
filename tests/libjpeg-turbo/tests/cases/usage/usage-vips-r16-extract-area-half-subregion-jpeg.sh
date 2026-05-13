#!/usr/bin/env bash
# @testcase: usage-vips-r16-extract-area-half-subregion-jpeg
# @title: vips extract_area pulls a 32x24 subregion at (8,8) out of a 64x48 JPEG
# @description: Encodes a 64x48 PPM as JPEG via vips jpegsave then runs vips extract_area with offset (8,8) and size 32x24 into a new JPEG, asserting the output is JPEG-typed and vipsheader reports width: 32 and height: 24, exercising libjpeg-turbo's decode plus vips's crop into a re-encode.
# @timeout: 180
# @tags: usage, vips, jpeg, extract-area
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 64, 48
data = bytes([(((x * 3) ^ (y * 5)) & 0xff)
              for y in range(H) for x in range(W * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips extract_area "$tmpdir/in.jpg" "$tmpdir/out.jpg" 8 8 32 24

file "$tmpdir/out.jpg" | grep -q 'JPEG image data'
vipsheader -a "$tmpdir/out.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 32'
validator_assert_contains "$tmpdir/hdr" 'height: 24'
