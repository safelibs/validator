#!/usr/bin/env bash
# @testcase: usage-netpbm-pamtopng-transparent-trns-png
# @title: netpbm pamtopng -transparent emits tRNS chunk
# @description: Synthesises a 4x4 PPM containing known cyan pixels, encodes via pamtopng -transparent=rgb:00/ff/ff, walks the resulting PNG to confirm a 6-byte tRNS chunk is present (RGB color type stores three uint16 components naming the transparent color), and confirms the chunk's encoded color matches cyan (R=0, G=255, B=255 at 8-bit scale, packed into the uint16 fields).
# @timeout: 180
# @tags: usage, image, png, alpha, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.ppm" <<'EOF'
P3
4 4
255
0 255 255  10 20 30   40 50 60    70 80 90
0 255 255  100 110 120 130 140 150 160 170 180
0 255 255  190 200 210 220 230 240 250 5 5
0 255 255  15 25 35   45 55 65    75 85 95
EOF

pamtopng -transparent=rgb:00/ff/ff "$tmpdir/in.ppm" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

python3 - "$tmpdir/out.png" <<'PY'
import struct
import sys

data = open(sys.argv[1], 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
if not data.startswith(sig):
    raise SystemExit('not a PNG signature')
idx = len(sig)
chunks = []
ihdr = None
trns_payload = None
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    payload = data[idx + 8:idx + 8 + length]
    chunks.append(ctype)
    if ctype == 'IHDR':
        ihdr = struct.unpack('>IIBBBBB', payload)
    elif ctype == 'tRNS':
        trns_payload = payload
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
print(f'chunks: {chunks}')
if 'tRNS' not in chunks:
    raise SystemExit(f'expected tRNS chunk, got {chunks}')
# pamtopng on RGB input keeps PNG color type 2 (truecolor); for that color
# type tRNS is exactly 6 bytes: R, G, B as big-endian uint16.
if ihdr is None or ihdr[3] != 2:
    raise SystemExit(f'expected color type 2 (RGB), got IHDR={ihdr}')
if len(trns_payload) != 6:
    raise SystemExit(f'tRNS for RGB must be 6 bytes, got {len(trns_payload)}')
r, g, b = struct.unpack('>HHH', trns_payload)
# pamtopng encodes the channel values at the source bit-depth scale (8-bit
# input -> 0..255 instead of 0..65535), so rgb:00/ff/ff lands at (0, 255, 255).
if (r, g, b) != (0, 255, 255):
    raise SystemExit(f'expected tRNS=(0,255,255) for cyan, got ({r},{g},{b})')
print(f'tRNS OK, transparent color=({r},{g},{b})')
PY
