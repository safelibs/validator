#!/usr/bin/env bash
# @testcase: usage-vips-r18-invert-then-invert-roundtrip-jpeg
# @title: vips invert applied twice via .v intermediates preserves dimensions
# @description: Encodes a 24x16 RGB PPM as JPEG via vips jpegsave, runs vips invert twice through .v intermediate files, and asserts vipsheader reports the original 24x16 dimensions and 3 bands on the final output, exercising libjpeg-turbo decode followed by two successive vips invert operations.
# @timeout: 180
# @tags: usage, vips, jpeg, invert, double, r18
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 24, 16
data = bytes([(((x * 13) ^ (y * 29)) & 0xff)
              for y in range(H) for x in range(W * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips invert "$tmpdir/in.jpg" "$tmpdir/mid.v"
vips invert "$tmpdir/mid.v" "$tmpdir/out.v"

vipsheader "$tmpdir/out.v" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '24x16'
validator_assert_contains "$tmpdir/hdr" '3 bands'
