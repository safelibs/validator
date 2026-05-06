#!/usr/bin/env bash
# @testcase: usage-netpbm-r11-pamcrater-pnmgamma-png
# @title: netpbm pamcrater elevation pipes through pnmgamma into PNG
# @description: Generates a synthetic crater field with pamcrater, normalises the elevation tuple type via pnmgamma, and writes the result as a 16-bit grayscale PNG, exercising the elevation-to-pnm bridge.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pamcrater -width=64 -height=64 -number=20 2>/dev/null \
  | pnmgamma 1 \
  | pnmtopng >"$tmpdir/out.png"

file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
validator_assert_contains "$tmpdir/file.txt" '64 x 64'
validator_assert_contains "$tmpdir/file.txt" '16-bit grayscale'

python3 - "$tmpdir/out.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
width, height, bit_depth, color_type = struct.unpack('>IIBB', data[16:26])
assert (width, height) == (64, 64), (width, height)
assert bit_depth == 16, bit_depth
assert color_type == 0, color_type  # grayscale
PY
