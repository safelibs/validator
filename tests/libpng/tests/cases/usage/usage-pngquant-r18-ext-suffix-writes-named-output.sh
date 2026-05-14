#!/usr/bin/env bash
# @testcase: usage-pngquant-r18-ext-suffix-writes-named-output
# @title: pngquant --ext custom suffix writes a sibling PNG with the requested name
# @description: Runs pngquant --ext '-r18.png' against an input named in.png and asserts a sibling in-r18.png is produced, pinning the custom-extension naming behavior end-to-end through the libpng encoder.
# @timeout: 120
# @tags: usage, image, png, pngquant, ext, r18
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
        b += bytes(((x * 15) & 0xff, (y * 17) & 0xff, ((x + y) * 8) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --ext '-r18.png' 32 "$tmpdir/in.png"
test -f "$tmpdir/in-r18.png" \
  || { printf 'expected pngquant output at in-r18.png\n' >&2; exit 1; }

python3 - "$tmpdir/in-r18.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
_, _, _, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY
