#!/usr/bin/env bash
# @testcase: usage-vips-r17-colourspace-srgb-to-bw-one-band
# @title: vips colourspace srgb to b-w on a JPEG yields a single-band image
# @description: Encodes a 24x16 RGB PPM as JPEG, then runs vips colourspace from srgb to b-w with explicit source-space sRGB, asserting vipsheader reports 1 band and the original dimensions, exercising libjpeg-turbo decode followed by vips colourspace conversion through the srgb-to-bw route.
# @timeout: 180
# @tags: usage, vips, jpeg, colourspace, bw
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 24, 16
data = bytes([(((x * 5) ^ (y * 11)) & 0xff)
              for y in range(H) for x in range(W * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips colourspace "$tmpdir/in.jpg" "$tmpdir/out.v" b-w --source-space srgb

vipsheader "$tmpdir/out.v" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '24x16'
validator_assert_contains "$tmpdir/hdr" '1 band'
