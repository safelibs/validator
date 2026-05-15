#!/usr/bin/env bash
# @testcase: usage-pngquant-r19-floyd-strength-quarter-paletted
# @title: pngquant --floyd=0.25 yields a paletted PNG output
# @description: Quantises a 20x20 RGB PNG with pngquant --floyd=0.25 at 32 colors and asserts the output PNG color type byte is 3 (paletted), pinning that a fractional Floyd-Steinberg strength still produces an indexed image.
# @timeout: 120
# @tags: usage, image, png, pngquant, floyd, r19
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
        b += bytes(((x * 12) & 0xff, (y * 11) & 0xff, ((x + 2 * y) * 5) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngquant --force --floyd=0.25 --output "$tmpdir/out.png" 32 "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
_, _, _, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY
