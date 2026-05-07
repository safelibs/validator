#!/usr/bin/env bash
# @testcase: usage-pngquant-r14-transbug-flag-paletted
# @title: pngquant --transbug accepts the workaround flag and writes a valid paletted PNG
# @description: Quantises a synthetic 24x24 PNG with pngquant --transbug (the documented workaround flag for readers that expect the fully-transparent palette entry to be last) and verifies the output is a valid 24x24 paletted PNG — locking in that the --transbug flag is a recognised option on Ubuntu 24.04 pngquant 2.18.0.
# @timeout: 120
# @tags: usage, image, png, cli, transbug
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
        b += bytes(((x * 10) & 0xff, (y * 10) & 0xff, ((x + y) * 4) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --transbug -o "$tmpdir/out.png" 32 "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (24, 24), (w, h)
assert ctype == 3, f'expected paletted PNG (ctype 3), got {ctype}'
PY
