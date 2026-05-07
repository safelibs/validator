#!/usr/bin/env bash
# @testcase: usage-pngquant-r13-short-s-speed-flag
# @title: pngquant -s short flag accepts a speed value and produces a valid PNG
# @description: Quantises a synthetic PNG with pngquant -s 4 (the documented default speed/quality knob) and verifies the resulting output is a valid PNG of the original dimensions, locking in the short -s alias of --speed as functional on Ubuntu 24.04 — distinguishing it from the existing --speed long-form tests.
# @timeout: 120
# @tags: usage, image, png, cli, short-flag, speed
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 40, 40
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 6) & 0xff, (y * 6) & 0xff, ((x ^ y) * 3) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force -s 4 -o "$tmpdir/out.png" 32 "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (40, 40), (w, h)
# A quantised result must be a paletted PNG (color type 3).
assert ctype == 3, f'expected paletted PNG (ctype 3), got {ctype}'
PY
