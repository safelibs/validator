#!/usr/bin/env bash
# @testcase: usage-pngquant-r19-stdin-stdout-pipe-paletted
# @title: pngquant reads PNG bytes from stdin and emits a paletted PNG on stdout
# @description: Pipes a generated PNG into pngquant - - 64 and reads the resulting PNG from stdout, asserting the IHDR color type byte is 3 (paletted), pinning the stdin/stdout streaming path through the libpng encoder.
# @timeout: 120
# @tags: usage, image, png, pngquant, stdio, r19
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
        b += bytes(((x * 14) & 0xff, (y * 15) & 0xff, ((x + y) * 6) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant 64 - <"$tmpdir/in.png" >"$tmpdir/out.png"
validator_require_file "$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
_, _, _, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY
