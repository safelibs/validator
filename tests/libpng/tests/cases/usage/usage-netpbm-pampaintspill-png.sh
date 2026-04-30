#!/usr/bin/env bash
# @testcase: usage-netpbm-pampaintspill-png
# @title: netpbm pampaintspill spreads paint sources on PNG-derived input
# @description: Builds a sparse PPM with two off-corner red and blue pixels on a black background, encodes through PNG and back, runs pampaintspill --bgcolor=black, and verifies the result is a 4x4 PPM where every pixel has at least some red or blue contribution (the background has been painted over).
# @timeout: 180
# @tags: usage, image, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pampaintspill-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 4x4 PPM with two paint sources on a black background.
cat >"$tmpdir/spots.ppm" <<'EOF'
P3
4 4
255
255 0 0  0 0 0  0 0 0  0 0 0
0 0 0    0 0 0  0 0 0  0 0 0
0 0 0    0 0 0  0 0 0  0 0 0
0 0 0    0 0 0  0 0 0  0 0 255
EOF

pnmtopng "$tmpdir/spots.ppm" >"$tmpdir/spots.png"
file "$tmpdir/spots.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopnm "$tmpdir/spots.png" >"$tmpdir/spots-rt.ppm"
pampaintspill --bgcolor=black "$tmpdir/spots-rt.ppm" >"$tmpdir/spill.ppm"
pamfile "$tmpdir/spill.ppm" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '4 by 4'

python3 - "$tmpdir/spill.ppm" <<'PY'
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
if magic != b'P6':
    raise SystemExit(f'expected P6, got {magic!r}')
w = int(tok())
h = int(tok())
maxv = int(tok())
if (w, h, maxv) != (4, 4, 255):
    raise SystemExit(f'unexpected header {w}x{h}@{maxv}')
if data[idx] in b' \t\r\n':
    idx += 1
payload = data[idx:]
if len(payload) != 4 * 4 * 3:
    raise SystemExit(f'short payload {len(payload)}')

# Every pixel should have some red or blue (or both); the background is
# expected to have been painted over by the spill from the two sources.
fully_black = 0
for i in range(0, len(payload), 3):
    r, g, b = payload[i], payload[i + 1], payload[i + 2]
    if r == 0 and b == 0:
        fully_black += 1
if fully_black:
    raise SystemExit(
        f'expected pampaintspill to recolor every pixel, '
        f'but {fully_black} pixels remain (R=0, B=0)'
    )

# The two paint sources should remain saturated in their own channels.
# (0,0) is red source, (3,3) is blue source.
def pix(x, y):
    o = (y * w + x) * 3
    return payload[o], payload[o + 1], payload[o + 2]


r0 = pix(0, 0)
r3 = pix(3, 3)
if r0[0] < 200:
    raise SystemExit(f'red source weakened: {r0}')
if r3[2] < 200:
    raise SystemExit(f'blue source weakened: {r3}')
PY
