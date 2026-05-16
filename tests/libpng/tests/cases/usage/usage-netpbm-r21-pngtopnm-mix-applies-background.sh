#!/usr/bin/env bash
# @testcase: usage-netpbm-r21-pngtopnm-mix-applies-background
# @title: netpbm pngtopnm -mix -background flattens RGBA to fully-opaque RGB pixels
# @description: Builds an RGBA PNG with a fully-transparent pixel at (0,0), decodes via pngtopnm -mix -background=rgb:ff/00/00, and asserts the resulting P6 PPM has that pixel set to (255,0,0), pinning libpng's alpha compositing path under netpbm's mix/background semantics.
# @timeout: 120
# @tags: usage, png, netpbm, pngtopnm, mix-alpha, r21
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 4, 4
body = bytearray()
for y in range(H):
    for x in range(W):
        body += bytes((50, 50, 50))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + body)
PY
python3 - "$tmpdir/mask.pgm" <<'PY'
import sys
W, H = 4, 4
body = bytearray()
for y in range(H):
    for x in range(W):
        # (0,0) transparent, others opaque
        body.append(0 if (x == 0 and y == 0) else 255)
open(sys.argv[1], 'wb').write(f'P5\n{W} {H}\n255\n'.encode() + body)
PY

pnmtopng -alpha "$tmpdir/mask.pgm" "$tmpdir/in.ppm" >"$tmpdir/rgba.png"
pngtopnm -mix -background=rgb:ff/00/00 "$tmpdir/rgba.png" >"$tmpdir/out.ppm"

python3 - "$tmpdir/out.ppm" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
# Parse P6 header
i = data.index(b'\n', data.index(b'\n', data.index(b'\n') + 1) + 1) + 1
pixels = data[i:]
r, g, b = pixels[0], pixels[1], pixels[2]
# (0,0) flattened against red background -> red
assert (r, g, b) == (255, 0, 0), (r, g, b)
PY
