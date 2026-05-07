#!/usr/bin/env bash
# @testcase: usage-netpbm-r13-pnmtopng-chroma-emits-chrm-chunk
# @title: netpbm pnmtopng -rgb writes a cHRM chunk with eight 4-byte fields
# @description: Encodes a synthetic PPM with pnmtopng -rgb supplying explicit white-point and primary chromaticity coordinates as a single quoted string of eight floats, and walks the resulting PNG to confirm a cHRM chunk is present whose payload is exactly 32 bytes (eight 4-byte big-endian integers for white-point and RGB primaries), locking in the cHRM emission path through libpng.
# @timeout: 120
# @tags: usage, png, netpbm, chrm
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
        b += bytes((x * 16 & 0xff, y * 16 & 0xff, 32))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

# Ubuntu 24.04 pnmtopng deprecates -chroma and accepts -rgb with a single
# string-form argument carrying eight floats:
#   wp_x wp_y r_x r_y g_x g_y b_x b_y
# (here, the canonical sRGB chromaticities)
pnmtopng -rgb='0.3127 0.3290 0.64 0.33 0.30 0.60 0.15 0.06' \
  "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
idx = 8
chrm_payload = None
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    payload = data[idx + 8:idx + 8 + length]
    if ctype == 'cHRM':
        chrm_payload = payload
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if chrm_payload is None:
    raise SystemExit('expected a cHRM chunk')
if len(chrm_payload) != 32:
    raise SystemExit(f'cHRM payload must be 32 bytes (8x uint32), got {len(chrm_payload)}')
fields = struct.unpack('>8I', chrm_payload)
# All fields must be in the [0, 100000] range that PNG stores chromaticity in.
for v in fields:
    if not (0 <= v <= 100000):
        raise SystemExit(f'cHRM field out of range: {v} not in [0, 100000]')
# Sanity: the white-point x stored as round(0.3127*100000) = 31270.
wp_x = fields[0]
if abs(wp_x - 31270) > 5:
    raise SystemExit(f'white-point x mismatch: expected ~31270, got {wp_x}')
PY
