#!/usr/bin/env bash
# @testcase: usage-pngquant-r18-nofs-disables-dither-paletted
# @title: pngquant --nofs (no Floyd-Steinberg) still emits a paletted PNG
# @description: Quantises a 24x24 RGB PNG with pngquant --nofs at 32 colors and asserts the output is a color-type-3 paletted PNG, pinning that disabling dithering does not change the libpng-emitted output color type.
# @timeout: 120
# @tags: usage, image, png, pngquant, nofs, r18
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 24, 24
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 9) & 0xff, (y * 11) & 0xff, ((x + y) * 4) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngquant --force --nofs --output "$tmpdir/out.png" 32 "$tmpdir/in.png"
validator_require_file "$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
_, _, _, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY
