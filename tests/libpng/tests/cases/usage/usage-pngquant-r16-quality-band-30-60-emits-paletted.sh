#!/usr/bin/env bash
# @testcase: usage-pngquant-r16-quality-band-30-60-emits-paletted
# @title: pngquant --quality 30-60 emits a paletted PNG of original dimensions
# @description: Quantises a synthetic 24x24 PNG with pngquant --quality 30-60 (a moderate quality band) and asserts the output is a valid 24x24 PNG with color type 3 (paletted) — distinct from existing quality-low (0-50) and quality-high tests.
# @timeout: 120
# @tags: usage, image, png, cli, quality
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
        b += bytes(((x * 10) & 0xff, (y * 10) & 0xff, ((x + y) * 5) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --quality 30-60 -o "$tmpdir/out.png" 64 "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (24, 24), (w, h)
assert ctype == 3, f'expected paletted PNG (ctype 3), got {ctype}'
PY
