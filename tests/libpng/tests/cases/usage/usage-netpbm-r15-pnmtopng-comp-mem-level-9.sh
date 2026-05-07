#!/usr/bin/env bash
# @testcase: usage-netpbm-r15-pnmtopng-comp-mem-level-9
# @title: netpbm pnmtopng -comp_mem_level=9 writes a valid PNG with max zlib mem-level
# @description: Encodes a synthetic 24x24 PPM with pnmtopng -comp_mem_level=9 (the documented maximum-memory zlib setting) and verifies the output is a valid 24x24 RGB PNG — locking in that the zlib memory-level override path is reachable on Ubuntu 24.04 netpbm.
# @timeout: 120
# @tags: usage, png, netpbm, zlib-mem-level
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 24, 24
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 10 & 0xff, y * 10 & 0xff, 96))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng -comp_mem_level=9 "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n', data[:8]
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (24, 24), (w, h)
assert ctype == 2, f'expected color type 2 (RGB), got {ctype}'
PY
