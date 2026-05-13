#!/usr/bin/env bash
# @testcase: usage-pngquant-r16-ext-tinyq-suffix
# @title: pngquant --ext=.tinyq.png emits the explicit ext suffix
# @description: Quantises an input PNG with pngquant --ext=.tinyq.png --force and asserts the output file "in.tinyq.png" exists, pinning the documented --ext suffix override — distinct from existing fs8/or8/dot-q ext coverage.
# @timeout: 120
# @tags: usage, image, png, cli, ext
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
        b += bytes(((x * 16) & 0xff, (y * 16) & 0xff, 50))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

(cd "$tmpdir" && pngquant --force --ext=.tinyq.png 16 in.png)

test -f "$tmpdir/in.png"
test -f "$tmpdir/in.tinyq.png"

python3 - "$tmpdir/in.tinyq.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (16, 16), (w, h)
assert ctype == 3, ctype
PY
