#!/usr/bin/env bash
# @testcase: usage-netpbm-r19-pnmtopng-interlace-byte-set
# @title: netpbm pnmtopng -interlace marks the IHDR interlace byte non-zero
# @description: Encodes a 10x10 PPM with pnmtopng -interlace and inspects byte 28 (interlace method) of the IHDR chunk, asserting it is non-zero, pinning the Adam7 interlace flag in the libpng-emitted output.
# @timeout: 120
# @tags: usage, png, netpbm, pnmtopng, interlace, r19
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 10, 10
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 20) & 0xff, (y * 22) & 0xff, ((x + y) * 11) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng -interlace "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
# IHDR layout: bytes 16..25 = width, height, bit-depth, color-type, compression, filter, interlace
w, h, depth, ctype, comp, filt, interlace = struct.unpack('>IIBBBBB', data[16:29])
assert interlace == 1, f'expected interlace=1, got {interlace}'
PY
