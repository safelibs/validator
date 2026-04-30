#!/usr/bin/env bash
# @testcase: usage-pngquant-speed-ten-png
# @title: pngquant --speed 10
# @description: Quantizes a synthesised gradient PNG with --speed 10 (near the fastest setting) to 8 colors and verifies the output is a valid PNG with at most 8 unique colors.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-speed-ten-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a small RGB gradient PPM, encode to PNG via pnmtopng, then quantize.
python3 - "$tmpdir/in.ppm" <<'PY'
import sys

with open(sys.argv[1], 'w', encoding='ascii') as fh:
    fh.write('P3\n16 1\n255\n')
    for value in range(16):
        red = value * 16
        green = 255 - value * 12
        blue = (value * 23) % 256
        fh.write(f'{red} {green} {blue} ')
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
file "$tmpdir/in.png" | tee "$tmpdir/file-in"
validator_assert_contains "$tmpdir/file-in" 'PNG image data'

pngquant --force --speed 10 --output "$tmpdir/out.png" 8 "$tmpdir/in.png"
file "$tmpdir/out.png" | tee "$tmpdir/file-out"
validator_assert_contains "$tmpdir/file-out" 'PNG image data'

pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
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
if magic != b'P6':
    raise SystemExit(f'expected P6, got {magic!r}')
w = int(tok())
h = int(tok())
maxv = int(tok())
if (w, h) != (16, 1):
    raise SystemExit(f'unexpected dims {w}x{h}')
if data[idx] in b' \t\r\n':
    idx += 1
payload = data[idx:]
if len(payload) != w * h * 3:
    raise SystemExit('short payload')
colors = {payload[i:i + 3] for i in range(0, len(payload), 3)}
if len(colors) > 8:
    raise SystemExit(f'expected <=8 colors, got {len(colors)}')
PY
