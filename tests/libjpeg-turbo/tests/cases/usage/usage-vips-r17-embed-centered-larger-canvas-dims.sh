#!/usr/bin/env bash
# @testcase: usage-vips-r17-embed-centered-larger-canvas-dims
# @title: vips embed centers a small JPEG in a larger canvas with correct dims
# @description: Encodes a 20x16 PPM as JPEG then runs vips embed at offset (10, 8) into a 40x32 canvas, asserting vipsheader reports the canvas dimensions 40x32 and the output is a JPEG-typed file, exercising libjpeg-turbo decode followed by vips embed canvas placement (distinct from r16 gravity which uses the gravity operator).
# @timeout: 180
# @tags: usage, vips, jpeg, embed
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 20, 16
data = bytes([(((x * 13) ^ (y * 19)) & 0xff)
              for y in range(H) for x in range(W * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips embed "$tmpdir/in.jpg" "$tmpdir/out.jpg" 10 8 40 32

file "$tmpdir/out.jpg" | grep -q 'JPEG image data'
vipsheader -a "$tmpdir/out.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 40'
validator_assert_contains "$tmpdir/hdr" 'height: 32'
