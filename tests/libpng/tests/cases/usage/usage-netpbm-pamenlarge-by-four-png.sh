#!/usr/bin/env bash
# @testcase: usage-netpbm-pamenlarge-by-four-png
# @title: netpbm pamenlarge by 4 on PNG-derived PGM
# @description: Decodes a synthesised 2x2 PNG to PGM, enlarges it 4x with pamenlarge, and verifies the output is exactly 8x8 with each source pixel replicated into the expected 4x4 block.
# @timeout: 120
# @tags: usage, image, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamenlarge-by-four-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.pgm" <<'EOF'
P2
2 2
255
10 20
30 40
EOF
pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"
file "$tmpdir/in.png" | tee "$tmpdir/in.file"
validator_assert_contains "$tmpdir/in.file" 'PNG image data'

pngtopnm "$tmpdir/in.png" >"$tmpdir/raw.pgm"
pamenlarge 4 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"

python3 - "$tmpdir/out.pgm" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
idx = 0
def skip_ws():
    global idx
    while idx < len(data):
        b = data[idx]
        if b in b' \t\r\n':
            idx += 1
            continue
        if b == 35:
            while idx < len(data) and data[idx] not in (10, 13):
                idx += 1
            continue
        break
def tok():
    global idx
    skip_ws()
    s = idx
    while idx < len(data) and data[idx] not in b' \t\r\n':
        idx += 1
    return data[s:idx]
magic = tok()
if magic != b'P5':
    raise SystemExit(f'expected P5, got {magic!r}')
w = int(tok()); h = int(tok()); _ = int(tok())
if data[idx] in b' \t\r\n':
    idx += 1
payload = list(data[idx:])
if (w, h) != (8, 8):
    raise SystemExit(f'expected 8x8, got {w}x{h}')

src = [[10, 20], [30, 40]]
expected = []
for sy in range(2):
    for _ in range(4):       # row replication
        row = []
        for sx in range(2):
            row.extend([src[sy][sx]] * 4)  # column replication
        expected.extend(row)
if payload != expected:
    raise SystemExit(f'unexpected payload\n got: {payload}\nwant: {expected}')

# Spot-check the four corner blocks: each 4x4 quadrant must be uniform.
def block(x, y):
    return [payload[(y + dy) * 8 + (x + dx)] for dy in range(4) for dx in range(4)]

corners = {
    (0, 0): 10,
    (4, 0): 20,
    (0, 4): 30,
    (4, 4): 40,
}
for (x, y), v in corners.items():
    b = block(x, y)
    if any(p != v for p in b):
        raise SystemExit(f'block at ({x},{y}) not uniform={v}: {b}')
print('pamenlarge 4x replication verified')
PY
