#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-transparent-color-png
# @title: netpbm pnmtopng -transparent specific color
# @description: Builds a 4x4 PPM containing a known magenta pixel, encodes it with pnmtopng -transparent =rgb:ff/00/ff, and confirms the resulting PNG carries a tRNS chunk and that pngtopam exposes a four-channel image whose alpha channel is 0 exactly at the magenta pixels.
# @timeout: 180
# @tags: usage, image, png, alpha
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.ppm" <<'EOF'
P3
4 4
255
255 0 255  0 0 0      255 255 255 10 20 30
40 50 60   255 0 255  70 80 90    100 110 120
130 140 150 160 170 180 255 0 255 190 200 210
220 230 240 250 5 5    15 25 35    255 0 255
EOF

pnmtopng -transparent =rgb:ff/00/ff "$tmpdir/in.ppm" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

# Confirm a tRNS chunk is present.
python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
assert data.startswith(sig)
idx = len(sig)
chunks = []
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    chunks.append(ctype)
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if 'tRNS' not in chunks:
    raise SystemExit(f'expected tRNS chunk in -transparent output, got {chunks}')
PY

# Decode with alpha channel and confirm magenta pixels are transparent.
pngtopam -alphapam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pam.file"
validator_assert_contains "$tmpdir/pam.file" '4 by 4'

python3 - "$tmpdir/out.pam" <<'PY'
import sys

data = open(sys.argv[1], 'rb').read()
# Parse PAM header.
header, _, body = data.partition(b'ENDHDR\n')
fields = {}
for line in header.splitlines():
    if not line or line.startswith(b'#') or line == b'P7':
        continue
    k, _, v = line.partition(b' ')
    fields[k.decode()] = v.decode().strip()
w = int(fields['WIDTH'])
h = int(fields['HEIGHT'])
depth = int(fields['DEPTH'])
maxv = int(fields['MAXVAL'])
if depth != 4 or maxv != 255 or (w, h) != (4, 4):
    raise SystemExit(f'unexpected pam: w={w} h={h} depth={depth} maxv={maxv}')
expected_transparent = {(0, 0), (1, 1), (2, 2), (3, 3)}
got_transparent = set()
for y in range(h):
    for x in range(w):
        off = (y * w + x) * 4
        r, g, b, a = body[off:off + 4]
        if a == 0:
            got_transparent.add((x, y))
if got_transparent != expected_transparent:
    raise SystemExit(f'transparent pixels mismatch: expected {expected_transparent} got {got_transparent}')
PY
