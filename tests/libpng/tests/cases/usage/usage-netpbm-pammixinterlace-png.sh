#!/usr/bin/env bash
# @testcase: usage-netpbm-pammixinterlace-png
# @title: netpbm pammixinterlace blends rows of PNG-derived PGM
# @description: Decodes a synthesised 2x4 PNG to a PGM, runs pammixinterlace -filter=linear, and verifies the output dimensions are preserved and that interior rows are a (1/4, 1/2, 1/4) blend of their neighbors per the linear filter.
# @timeout: 180
# @tags: usage, image, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pammixinterlace-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 2 columns x 4 rows grayscale ramp; row pixels are constant per row so we
# can predict the linear-blend output exactly.
cat >"$tmpdir/in.pgm" <<'EOF'
P2
2 4
255
40 40
80 80
160 160
240 240
EOF
pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"
file "$tmpdir/in.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopnm "$tmpdir/in.png" >"$tmpdir/raw.pgm"
pammixinterlace -filter=linear "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
pamfile "$tmpdir/out.pgm" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '2 by 4'

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
w = int(tok())
h = int(tok())
maxv = int(tok())
if (w, h, maxv) != (2, 4, 255):
    raise SystemExit(f'unexpected header {w}x{h}@{maxv}')
if data[idx] in b' \t\r\n':
    idx += 1
payload = list(data[idx:])
if len(payload) != 8:
    raise SystemExit(f'expected 8 bytes, got {len(payload)}')

# Each row has constant pixels; rows are [40, 80, 160, 240]. The linear
# pammixinterlace filter computes interior_out[r] = 0.25*in[r-1] + 0.5*in[r]
# + 0.25*in[r+1]. Edge rows get clamped (the filter typically reuses the
# nearest available neighbour), so we only assert the well-defined interior
# rows here.
rows = [payload[r * 2:(r + 1) * 2] for r in range(4)]
for r in range(4):
    if rows[r][0] != rows[r][1]:
        raise SystemExit(f'row {r} not constant across columns: {rows[r]}')
in_rows = [40, 80, 160, 240]
out_rows = [rows[r][0] for r in range(4)]
for r in (1, 2):
    expected = round(0.25 * in_rows[r - 1] + 0.5 * in_rows[r] + 0.25 * in_rows[r + 1])
    if abs(out_rows[r] - expected) > 1:
        raise SystemExit(
            f'row {r} unexpected blend: got {out_rows[r]} expected ~{expected}'
        )
PY
