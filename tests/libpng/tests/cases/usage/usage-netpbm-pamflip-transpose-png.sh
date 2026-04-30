#!/usr/bin/env bash
# @testcase: usage-netpbm-pamflip-transpose-png
# @title: netpbm pamflip -transpose on PNG-derived PGM
# @description: Decodes a synthesised 3x2 PNG, applies pamflip -transpose, and verifies the resulting 2x3 PGM payload equals the matrix transpose of the original pixel grid.
# @timeout: 120
# @tags: usage, image, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamflip-transpose-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 3 columns x 2 rows grayscale: row-major values 10,20,30 / 40,50,60.
cat >"$tmpdir/in.pgm" <<'EOF'
P2
3 2
255
10 20 30
40 50 60
EOF
pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"
file "$tmpdir/in.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopnm "$tmpdir/in.png" >"$tmpdir/raw.pgm"
pamflip -transpose "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"

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
if (w, h) != (2, 3):
    raise SystemExit(f'expected 2x3 transpose, got {w}x{h}')
# Original (row-major): [[10,20,30],[40,50,60]].
# Transpose (row-major): [[10,40],[20,50],[30,60]].
expected = [10, 40, 20, 50, 30, 60]
if payload != expected:
    raise SystemExit(f'unexpected payload {payload}')
PY
