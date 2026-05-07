#!/usr/bin/env bash
# @testcase: usage-netpbm-r15-pnmtopng-background-bkgd-chunk
# @title: netpbm pnmtopng -background=red emits a bKGD chunk
# @description: Encodes a synthetic 16x16 PPM with pnmtopng -background=red (the documented option that records a suggested background color) and walks the resulting PNG to confirm at least one bKGD chunk is present — locking in libpng's background-color emission path on Ubuntu 24.04 netpbm. Distinct from -transparent, -alpha, and -srgbintent.
# @timeout: 120
# @tags: usage, png, netpbm, bkgd
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 16, 16
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 16 & 0xff, y * 16 & 0xff, 96))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng -background=red "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n', data[:8]
idx = 8
bkgd = 0
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    if ctype == 'bKGD':
        bkgd += 1
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if bkgd < 1:
    raise SystemExit(f'expected at least one bKGD chunk, got {bkgd}')
PY
