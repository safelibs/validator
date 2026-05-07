#!/usr/bin/env bash
# @testcase: usage-netpbm-r15-pnmtopng-srgbintent-saturation
# @title: netpbm pnmtopng -srgbintent=saturation emits an sRGB chunk with rendering-intent byte 2
# @description: Encodes a synthetic PPM with pnmtopng -srgbintent=saturation (one of the four documented named tokens) and walks the chunk stream to confirm exactly one sRGB chunk is present whose 1-byte payload equals 2 — locking in the saturation rendering-intent emission path. Distinct from the perceptual (0) intent test in r13.
# @timeout: 120
# @tags: usage, png, netpbm, srgb, saturation
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
        b += bytes((x * 10 & 0xff, y * 10 & 0xff, 64))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng -srgbintent=saturation "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n', data[:8]
idx = 8
srgb_payloads = []
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    payload = data[idx + 8:idx + 8 + length]
    if ctype == 'sRGB':
        srgb_payloads.append(payload)
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if len(srgb_payloads) != 1:
    raise SystemExit(f'expected exactly one sRGB chunk, got {len(srgb_payloads)}')
payload = srgb_payloads[0]
if len(payload) != 1:
    raise SystemExit(f'sRGB payload must be 1 byte, got {len(payload)}')
if payload[0] != 2:
    raise SystemExit(f'sRGB rendering intent must be 2 (saturation), got {payload[0]}')
PY
