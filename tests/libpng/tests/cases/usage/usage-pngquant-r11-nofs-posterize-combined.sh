#!/usr/bin/env bash
# @testcase: usage-pngquant-r11-nofs-posterize-combined
# @title: pngquant --nofs --posterize 2 combined produces 4-bit colormap PNG
# @description: Combines --nofs (Floyd-Steinberg disabled) with --posterize 2 (truncate two least-significant bits per channel) at 16 colors and verifies the output is a valid PNG with a paletted color type, exercising the no-dither + posterize composition path.
# @timeout: 180
# @tags: usage, image, png
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
        b += bytes(((x * 8) & 0xff, (y * 8) & 0xff, ((x + y) * 4) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --nofs --posterize 2 --force --output "$tmpdir/out.png" 16 "$tmpdir/in.png"

file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
validator_assert_contains "$tmpdir/file.txt" 'colormap'

python3 - "$tmpdir/out.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
_, _, _, color_type = struct.unpack('>IIBB', data[16:26])
assert color_type == 3, color_type  # palette / colormap
PY
