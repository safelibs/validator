#!/usr/bin/env bash
# @testcase: usage-pngquant-r19-colors-five-paletted-output
# @title: pngquant with a 5-color target produces a paletted PNG
# @description: Quantises a synthetic gradient PNG to 5 colors via pngquant and asserts the output is a color-type-3 paletted PNG, pinning the odd, non-power-of-two palette-size path through the libpng encoder.
# @timeout: 120
# @tags: usage, image, png, pngquant, colors, r19
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
        b += bytes(((x * 16) & 0xff, (y * 17) & 0xff, ((x ^ y) * 11) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngquant --force --output "$tmpdir/out.png" 5 "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
_, _, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY
