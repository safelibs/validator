#!/usr/bin/env bash
# @testcase: usage-pngquant-r21-quality-band-30-70-paletted-output
# @title: pngquant --quality 30-70 produces a paletted PNG with a PLTE chunk
# @description: Encodes a 24x16 truecolor PNG then runs pngquant --quality 30-70, asserting the resulting output contains a PLTE chunk (libpng palette emission) and decodes back to an 8-bit IHDR via the gAMA-free standard pipeline.
# @timeout: 120
# @tags: usage, png, pngquant, quality, plte, r21
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 24, 16
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 7) & 0xff, (y * 9) & 0xff, ((x ^ y) * 5) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --quality 30-70 --output "$tmpdir/out.png" "$tmpdir/in.png"
python3 - "$tmpdir/out.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
assert b'PLTE' in data
_, _, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert depth == 8, depth
PY
