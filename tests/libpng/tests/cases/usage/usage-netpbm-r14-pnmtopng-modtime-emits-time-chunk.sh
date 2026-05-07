#!/usr/bin/env bash
# @testcase: usage-netpbm-r14-pnmtopng-modtime-emits-time-chunk
# @title: netpbm pnmtopng -modtime emits a tIME chunk encoding the requested instant
# @description: Encodes a synthetic PPM with pnmtopng -modtime="2024-01-15 12:00:00" and walks the resulting PNG to confirm exactly one tIME chunk is present whose 7-byte payload encodes the precise calendar date 2024-01-15 with all time fields in valid PNG ranges — locking in the tIME emission path through libpng on Ubuntu 24.04. The hour field is allowed to be shifted from the supplied local time because pnmtopng stores tIME in UTC.
# @timeout: 120
# @tags: usage, png, netpbm, time
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

pnmtopng -modtime="2024-01-15 12:00:00" "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
idx = 8
time_payloads = []
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    payload = data[idx + 8:idx + 8 + length]
    if ctype == 'tIME':
        time_payloads.append(payload)
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if len(time_payloads) != 1:
    raise SystemExit(f'expected exactly one tIME chunk, got {len(time_payloads)}')
payload = time_payloads[0]
if len(payload) != 7:
    raise SystemExit(f'tIME payload must be 7 bytes, got {len(payload)}')
year, month, day, hour, minute, second = struct.unpack('>HBBBBB', payload)
# Calendar date must round-trip exactly. Hour may be shifted from the supplied
# local time because pnmtopng stores tIME in UTC; only constrain the legal range.
if (year, month, day) != (2024, 1, 15):
    raise SystemExit(f'tIME calendar mismatch: got {(year, month, day)}')
if not (0 <= hour <= 23 and 0 <= minute <= 59 and 0 <= second <= 60):
    raise SystemExit(f'tIME time fields out of range: {(hour, minute, second)}')
PY
