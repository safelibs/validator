#!/usr/bin/env bash
# @testcase: usage-pngquant-r14-floyd-fractional-strength
# @title: pngquant --floyd=0.5 long-form fractional strength produces a valid paletted PNG
# @description: Quantises a synthetic 32x32 PNG with pngquant --floyd=0.5 (the documented long-form fractional dithering strength) and verifies the output is a valid 32x32 paletted PNG (color type 3) — locking in the long-form --floyd=N argument syntax with a fractional value as functional on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, image, png, cli, floyd-dither
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 32, 32
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 8) & 0xff, (y * 8) & 0xff, ((x ^ y) * 4) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --floyd=0.5 -o "$tmpdir/out.png" 32 "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (32, 32), (w, h)
assert ctype == 3, f'expected paletted PNG (ctype 3), got {ctype}'
PY
