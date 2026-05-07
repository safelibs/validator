#!/usr/bin/env bash
# @testcase: usage-netpbm-r13-pnmtopng-gamma-emits-gama-chunk
# @title: netpbm pnmtopng -gamma=0.45455 emits a gAMA chunk
# @description: Encodes a synthetic PPM with pnmtopng -gamma=0.45455 (the canonical sRGB gamma) and walks the chunk stream of the resulting PNG to confirm exactly one gAMA chunk is present whose 4-byte big-endian payload equals 45455 — pnmtopng stores the supplied gamma scaled by 100000 in the gAMA payload.
# @timeout: 120
# @tags: usage, png, netpbm, gamma
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
        b += bytes((x * 16 & 0xff, y * 16 & 0xff, 128))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng -gamma=0.45455 "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
idx = 8
gama_payloads = []
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    payload = data[idx + 8:idx + 8 + length]
    if ctype == 'gAMA':
        gama_payloads.append(payload)
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if len(gama_payloads) != 1:
    raise SystemExit(f'expected exactly one gAMA chunk, got {len(gama_payloads)}')
payload = gama_payloads[0]
if len(payload) != 4:
    raise SystemExit(f'gAMA payload must be 4 bytes, got {len(payload)}')
(value,) = struct.unpack('>I', payload)
# pnmtopng documents gamma * 100000 as the on-disk value.
if value != 45455:
    raise SystemExit(f'expected gAMA payload 45455, got {value}')
PY
