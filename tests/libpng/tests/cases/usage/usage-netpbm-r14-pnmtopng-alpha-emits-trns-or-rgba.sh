#!/usr/bin/env bash
# @testcase: usage-netpbm-r14-pnmtopng-alpha-emits-trns-or-rgba
# @title: netpbm pnmtopng -alpha=mask.pgm encodes per-pixel transparency into the PNG
# @description: Encodes a 16x16 RGB PPM with pnmtopng -alpha pointing at a 16x16 PGM transparency mask, and walks the chunk stream of the resulting PNG to confirm transparency was preserved either as an RGBA color type (6) or via a tRNS chunk paired with a paletted color type — locking in that the pnmtopng alpha-mask path through libpng produces a structurally valid transparent PNG.
# @timeout: 120
# @tags: usage, png, netpbm, alpha
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
        b += bytes((x * 16 & 0xff, y * 16 & 0xff, 64))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

python3 - "$tmpdir/alpha.pgm" <<'PY'
import sys
W, H = 16, 16
b = bytearray()
for y in range(H):
    for x in range(W):
        # Vary the mask across the image so it cannot be trivially compressed away.
        b.append((x * 16) & 0xff)
open(sys.argv[1], 'wb').write(f'P5\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng -alpha "$tmpdir/alpha.pgm" "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (16, 16), (w, h)
# Walk to find tRNS / PLTE / IDAT.
idx = 8
chunks = []
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    t = data[idx + 4:idx + 8].decode('ascii')
    chunks.append(t)
    idx += 8 + length + 4
    if t == 'IEND':
        break
# Either the PNG is RGBA (color type 6) or it is paletted (3) with a tRNS chunk.
if ctype == 6:
    pass
elif ctype == 3 and 'tRNS' in chunks:
    pass
else:
    raise SystemExit(f'expected RGBA (6) or paletted+tRNS, got ctype={ctype} chunks={chunks}')
PY
