#!/usr/bin/env bash
# @testcase: usage-netpbm-r13-pnmtopng-phys-aspect-2-1
# @title: netpbm pnmtopng -size emits a pHYs chunk recording the requested pixels-per-unit
# @description: Encodes a synthetic PPM with pnmtopng -size declaring 200 pixels-per-unit on the x axis and 100 on the y axis with unit specifier 0 (aspect-only), and walks the resulting PNG to confirm a pHYs chunk is present whose 9-byte payload encodes those exact integers — locking in pnmtopng's physical-pixel-size emission path through libpng.
# @timeout: 120
# @tags: usage, png, netpbm, phys
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
        b += bytes((x * 16 & 0xff, y * 16 & 0xff, 0))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

# Ubuntu 24.04 pnmtopng deprecates -phys and accepts -size with a single
# string-form argument carrying x_ppu, y_ppu, and the unit specifier.
pnmtopng -size='200 100 0' "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
idx = 8
phys_payload = None
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    payload = data[idx + 8:idx + 8 + length]
    if ctype == 'pHYs':
        phys_payload = payload
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if phys_payload is None:
    raise SystemExit('expected a pHYs chunk')
if len(phys_payload) != 9:
    raise SystemExit(f'pHYs payload must be 9 bytes, got {len(phys_payload)}')
x_ppu, y_ppu, unit = struct.unpack('>IIB', phys_payload)
if (x_ppu, y_ppu, unit) != (200, 100, 0):
    raise SystemExit(f'pHYs mismatch: got x={x_ppu} y={y_ppu} unit={unit}')
PY
