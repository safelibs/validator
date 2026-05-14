#!/usr/bin/env bash
# @testcase: usage-pngquant-r18-speed-1-produces-paletted
# @title: pngquant --speed 1 produces a color-type-3 paletted PNG output
# @description: Generates a 24x24 RGB PNG, runs pngquant --speed 1 at 64 colors, and asserts the output PNG color type byte is 3 (paletted) — pinning the highest-quality speed setting through the libpng-backed encoder.
# @timeout: 120
# @tags: usage, image, png, pngquant, speed, r18
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
        b += bytes(((x * 11) & 0xff, (y * 13) & 0xff, ((x + y) * 7) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --speed 1 --output "$tmpdir/out.png" 64 "$tmpdir/in.png"
validator_require_file "$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
_, _, _, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY
