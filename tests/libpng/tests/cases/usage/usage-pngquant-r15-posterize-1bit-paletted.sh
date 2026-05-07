#!/usr/bin/env bash
# @testcase: usage-pngquant-r15-posterize-1bit-paletted
# @title: pngquant --posterize 1 produces a valid paletted PNG of the original dimensions
# @description: Quantises a synthetic 32x32 PNG with pngquant --posterize 1 (the documented option that lowers per-channel precision; "1" is the smallest precision that pngquant accepts) and verifies the output is a valid 32x32 paletted PNG (color type 3) — locking in the posterize entry-point with a small precision argument on Ubuntu 24.04 pngquant 2.18.0. Distinct from --nofs and --speed flags.
# @timeout: 120
# @tags: usage, image, png, cli, posterize
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

pngquant --force --posterize 1 -o "$tmpdir/out.png" 32 "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (32, 32), (w, h)
assert ctype == 3, f'expected paletted PNG (ctype 3), got {ctype}'
PY
