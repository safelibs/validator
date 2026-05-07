#!/usr/bin/env bash
# @testcase: usage-netpbm-r12-pnmtopng-force-flag-png
# @title: netpbm pnmtopng -force keeps explicit truecolor encoding
# @description: Encodes a 16x16 PPM with pnmtopng -force which suppresses the optimization that would convert to a paletted PNG when colors are few, and verifies the output IHDR records color type 2 (truecolor RGB) rather than 3 (palette).
# @timeout: 120
# @tags: usage, png, netpbm, force
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# A 4-color image — without -force, pnmtopng would emit it as paletted.
python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 16, 16
palette = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)]
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(palette[(x + y) % 4])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng -force "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
_, _, _, color_type = struct.unpack('>IIBB', data[16:26])
assert color_type == 2, f'expected color type 2 (RGB), got {color_type}'
PY
