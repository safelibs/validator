#!/usr/bin/env bash
# @testcase: usage-netpbm-r15-pnmtopng-hist-emits-hist-chunk
# @title: netpbm pnmtopng -hist on a small palette image emits a hIST chunk
# @description: Encodes a tiny 4x4 PPM with only 4 distinct colors using pnmtopng -hist (the documented option that records color frequencies) and walks the resulting PNG to confirm at least one hIST chunk is present — locking in libpng's color-histogram emission path on Ubuntu 24.04 netpbm. The image is designed to be paletted so the hIST chunk is well-defined.
# @timeout: 120
# @tags: usage, png, netpbm, hist
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 4, 4
# Use only four distinct colors so libpng can produce a paletted PNG with a
# meaningful histogram.
palette = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)]
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(palette[(x + y) % 4])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng -hist "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n', data[:8]
idx = 8
hist = 0
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    if ctype == 'hIST':
        hist += 1
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if hist < 1:
    raise SystemExit(f'expected at least one hIST chunk, got {hist}')
PY
