#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-time-now-png
# @title: netpbm pnmtopng -time now adds tIME chunk
# @description: Encodes basn2c08.png with pnmtopng -time now and parses the resulting PNG's chunk structure to confirm a tIME chunk is present, has the canonical 7-byte payload, and that the embedded year is plausible (>= 2024).
# @timeout: 180
# @tags: usage, image, png, metadata
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/in.ppm"
pnmtopng -time now "$tmpdir/in.ppm" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys

data = open(sys.argv[1], 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
assert data.startswith(sig)
idx = len(sig)
time_payload = None
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    payload = data[idx + 8:idx + 8 + length]
    if ctype == 'tIME':
        time_payload = payload
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if time_payload is None:
    raise SystemExit('expected tIME chunk in -time now output')
if len(time_payload) != 7:
    raise SystemExit(f'tIME payload must be 7 bytes, got {len(time_payload)}')
year, month, day, hour, minute, second = struct.unpack('>HBBBBB', time_payload)
if year < 2024:
    raise SystemExit(f'tIME year unexpectedly old: {year}')
if not (1 <= month <= 12 and 1 <= day <= 31 and 0 <= hour <= 23 and 0 <= minute <= 59 and 0 <= second <= 60):
    raise SystemExit(f'tIME components out of range: {year}-{month}-{day} {hour}:{minute}:{second}')
print(f'tIME OK {year}-{month:02d}-{day:02d} {hour:02d}:{minute:02d}:{second:02d}')
PY
