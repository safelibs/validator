#!/usr/bin/env bash
# @testcase: usage-netpbm-r20-pngtopnm-paletted-decodes-rgb-ppm
# @title: netpbm pngtopnm on a paletted PNG decodes into a P6 PPM of matching dimensions
# @description: Generates a 16x10 RGB PPM, encodes via pnmtopng with -palette to force paletted output, validates the IHDR color type is 3 (paletted), then decodes the PNG with pngtopnm and asserts the output PPM begins with P6 magic and the dimensions match the source 16x10, exercising libpng's paletted-decode-to-RGB expansion through netpbm.
# @timeout: 120
# @tags: usage, png, netpbm, pngtopnm, paletted, r20
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 16, 10
b = bytearray()
# 4-color palette to keep paletted output trivially feasible
palette = [(20, 30, 40), (200, 30, 40), (20, 200, 40), (20, 30, 200)]
for y in range(H):
    for x in range(W):
        b += bytes(palette[(x + y) & 3])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmquant 4 "$tmpdir/in.ppm" 2>/dev/null | pnmtopng >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (16, 10), (w, h)
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY

pngtopnm "$tmpdir/out.png" >"$tmpdir/back.ppm"
python3 - "$tmpdir/back.ppm" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:2] == b'P6', data[:2]
PY
