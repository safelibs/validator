#!/usr/bin/env bash
# @testcase: usage-pngquant-r21-paletted-output-color-type-three
# @title: pngquant 64 emits a PNG with IHDR color type 3 (palette)
# @description: Generates a small RGB PNG, runs pngquant 64, and asserts the resulting paletted PNG's IHDR color type byte is exactly 3 (PNG palette mode), pinning libpng's palette color-type emission via pngquant's 64-color quantization.
# @timeout: 120
# @tags: usage, png, pngquant, color-type, paletted, r21
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 32, 32
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 11) & 0xff, (y * 13) & 0xff, ((x + y) * 7) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant 64 --output "$tmpdir/out.png" "$tmpdir/in.png"
python3 - "$tmpdir/out.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
_, _, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, f'expected color type 3 (palette), got {ctype}'
PY
