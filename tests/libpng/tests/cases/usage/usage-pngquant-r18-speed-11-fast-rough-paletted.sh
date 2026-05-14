#!/usr/bin/env bash
# @testcase: usage-pngquant-r18-speed-11-fast-rough-paletted
# @title: pngquant --speed 11 produces a paletted PNG on a small RGB input
# @description: Quantises a 16x16 RGB PNG with pngquant --speed 11 (fast & rough) at 32 colors and asserts the output is a color-type-3 paletted PNG, pinning the fastest setting's libpng-mediated output mode.
# @timeout: 120
# @tags: usage, image, png, pngquant, speed-fast, r18
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 16, 16
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 17) & 0xff, (y * 13) & 0xff, ((x * y) * 3) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngquant --force --speed 11 --output "$tmpdir/out.png" 32 "$tmpdir/in.png"
validator_require_file "$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
_, _, _, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY
