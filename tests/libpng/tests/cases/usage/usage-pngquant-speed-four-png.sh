#!/usr/bin/env bash
# @testcase: usage-pngquant-speed-four-png
# @title: pngquant --speed 4 PNG
# @description: Runs pngquant with the mid-default --speed 4 on a synthetic 4x4 RGB PPM and asserts the result is a 4x4 PNG bounded to 8 colours.
# @timeout: 120
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-speed-four-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/input.ppm" <<'PY'
import sys
with open(sys.argv[1], 'w', encoding='ascii') as h:
    h.write('P3\n4 4\n255\n')
    for i in range(16):
        r = (i * 19) % 256
        g = (i * 53) % 256
        b = (i * 97) % 256
        h.write(f'{r} {g} {b} ')
PY
pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"

pngquant --force --speed 4 --output "$tmpdir/out.png" 8 "$tmpdir/input.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
pamfile "$tmpdir/out.ppm" | tee "$tmpdir/pamfile.txt"
validator_assert_contains "$tmpdir/pamfile.txt" '4 by 4'

python3 - "$tmpdir/out.ppm" <<'PY'
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
w = int(tok()); h = int(tok()); _ = int(tok())
if data[idx] in b' \t\r\n':
    idx += 1
payload = data[idx:]
ch = 1 if magic == b'P5' else 3
colors = {tuple(payload[i:i+ch]) for i in range(0, len(payload), ch)}
if len(colors) > 8:
    raise SystemExit(f'expected <=8 colours after --colors 8, got {len(colors)}')
PY
