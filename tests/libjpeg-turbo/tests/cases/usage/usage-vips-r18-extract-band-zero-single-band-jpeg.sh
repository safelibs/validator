#!/usr/bin/env bash
# @testcase: usage-vips-r18-extract-band-zero-single-band-jpeg
# @title: vips extract_band 0 on an RGB JPEG yields a single-band intermediate
# @description: Encodes a 24x16 RGB PPM as JPEG via vips jpegsave then runs vips extract_band selecting band 0 with n=1, writing to .v output, and asserts vipsheader reports 1 band and the original dimensions, exercising libjpeg-turbo decode followed by vips extract_band on band index 0 (distinct from existing extract-band-jpeg coverage that selects a different band).
# @timeout: 180
# @tags: usage, vips, jpeg, extract-band, r18
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 24, 16
data = bytes([(((x * 17) ^ (y * 23)) & 0xff)
              for y in range(H) for x in range(W * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips extract_band "$tmpdir/in.jpg" "$tmpdir/out.v" 0 --n 1

vipsheader "$tmpdir/out.v" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '24x16'
validator_assert_contains "$tmpdir/hdr" '1 band'
