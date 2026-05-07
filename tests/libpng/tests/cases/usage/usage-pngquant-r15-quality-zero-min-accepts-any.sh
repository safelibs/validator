#!/usr/bin/env bash
# @testcase: usage-pngquant-r15-quality-zero-min-accepts-any
# @title: pngquant --quality=0-100 accepts an arbitrary-quality output (no min threshold)
# @description: Quantises a synthetic 24x24 PNG with pngquant --quality=0-100 (a full-range quality window where the lower bound of 0 means "accept any quantisation result") and verifies a valid 24x24 paletted PNG is produced — locking in that 0 is a legal lower bound on Ubuntu 24.04 pngquant 2.18.0 and that the program does not skip output when the lower bound is 0. Distinct from the existing --quality 99-100 high-bound test.
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
        b += bytes(((x * 10) & 0xff, (y * 10) & 0xff, 64))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --quality=0-100 -o "$tmpdir/out.png" 32 "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (24, 24), (w, h)
assert ctype == 3, f'expected paletted PNG (ctype 3), got {ctype}'
PY
