#!/usr/bin/env bash
# @testcase: usage-pngquant-r18-posterize-2-paletted-output
# @title: pngquant --posterize 2 produces a paletted PNG output
# @description: Quantises a 20x20 RGB PNG with pngquant --posterize 2 at 16 colors and asserts the output PNG color type byte is 3 (paletted), exercising the posterize-bits reduction path through the libpng-backed encoder.
# @timeout: 120
# @tags: usage, image, png, pngquant, posterize, r18
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 20, 20
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 12) & 0xff, (y * 14) & 0xff, ((x + 2 * y) * 6) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngquant --force --posterize 2 --output "$tmpdir/out.png" 16 "$tmpdir/in.png"
validator_require_file "$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
_, _, _, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY
