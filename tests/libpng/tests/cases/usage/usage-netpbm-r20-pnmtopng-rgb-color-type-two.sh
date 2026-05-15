#!/usr/bin/env bash
# @testcase: usage-netpbm-r20-pnmtopng-rgb-color-type-two
# @title: netpbm pnmtopng on a P6 PPM emits IHDR color type 2 (truecolor)
# @description: Builds a 16x10 P6 RGB PPM, encodes via pnmtopng, and asserts the IHDR color type byte is 2 (truecolor RGB, no alpha) and the bit depth is 8, exercising libpng's encoder color-type selection for plain RGB inputs.
# @timeout: 120
# @tags: usage, png, netpbm, pnmtopng, rgb, r20
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
# Use a larger image with >256 distinct colors so pnmtopng chooses RGB (color type 2)
# instead of auto-paletting low-color inputs.
W, H = 32, 24
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((((x * 17) ^ (y * 5)) & 0xff,
                    ((x * 23) + (y * 11)) & 0xff,
                    ((x * 31) ^ (y * 29) ^ 0x5a) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (32, 24), (w, h)
assert depth == 8, depth
assert ctype == 2, f'expected color type 2 (RGB), got {ctype}'
PY
