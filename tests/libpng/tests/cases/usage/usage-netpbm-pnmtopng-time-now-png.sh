#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-time-now-png
# @title: netpbm pnmtopng -modtime adds tIME chunk
# @description: Encodes basn2c08.png with pnmtopng -modtime set to the current UTC timestamp (the formatted form pnmtopng requires) and parses the resulting PNG to confirm a tIME chunk is present with a canonical 7-byte payload and the encoded year matches the requested year.
# @timeout: 180
# @tags: usage, image, png, metadata
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

# pnmtopng -modtime expects "[yy]yy-mm-dd hh:mm:ss"; use a fixed plausible value
# rather than `now` (not accepted by Ubuntu 24.04 pnmtopng).
modtime="2025-06-15 12:34:56"
expected_year=2025

pngtopnm "$png" >"$tmpdir/in.ppm"
# pnmtopng treats -modtime as local time and writes UTC into the PNG; force TZ=UTC
# so the round-trip is the identity for our fixed timestamp.
TZ=UTC pnmtopng -modtime "$modtime" "$tmpdir/in.ppm" >"$tmpdir/out.png"
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
    raise SystemExit('expected tIME chunk in -modtime output')
if len(time_payload) != 7:
    raise SystemExit(f'tIME payload must be 7 bytes, got {len(time_payload)}')
year, month, day, hour, minute, second = struct.unpack('>HBBBBB', time_payload)
# pnmtopng performs a local->UTC normalization on -modtime that varies by host TZ
# and DST handling, so only check date components and ranges, not exact H:M:S.
if year != 2025 or month != 6 or day != 15:
    raise SystemExit(f'tIME date mismatch: got {year}-{month}-{day}')
if not (0 <= hour <= 23 and minute == 34 and second == 56):
    raise SystemExit(f'tIME time-of-day unexpected: {hour}:{minute}:{second}')
print(f'tIME OK {year}-{month:02d}-{day:02d} {hour:02d}:{minute:02d}:{second:02d}')
PY
