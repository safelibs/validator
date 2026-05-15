#!/usr/bin/env bash
# @testcase: usage-pngquant-r20-32-colors-plte-chunk-present
# @title: pngquant 32 emits a PNG with an explicit PLTE chunk in the byte stream
# @description: Generates a PNG, runs pngquant 32 --output <path> <input>, and asserts the resulting paletted PNG byte stream contains the literal four-byte chunk type "PLTE", pinning libpng's palette chunk emission via pngquant's 32-color quantization path.
# @timeout: 120
# @tags: usage, png, pngquant, plte, palette, r20
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 20, 12
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 11) & 0xff, (y * 13) & 0xff, ((x + y) * 7) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant 32 --output "$tmpdir/out.png" "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
assert b'PLTE' in data, 'PLTE chunk missing'
PY
