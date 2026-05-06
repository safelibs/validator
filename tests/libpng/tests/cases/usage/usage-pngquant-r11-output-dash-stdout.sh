#!/usr/bin/env bash
# @testcase: usage-pngquant-r11-output-dash-stdout
# @title: pngquant --output - writes the quantised PNG to stdout
# @description: Uses --output - with a single named input file (not stdin) to redirect the quantised PNG to stdout, distinguishing this output path from the existing stdin/stdout pair.
# @timeout: 120
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
        b += bytes(((x * 8) & 0xff, (y * 8) & 0xff, ((x ^ y) * 4) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --output - 16 "$tmpdir/in.png" >"$tmpdir/out.png"

file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'

python3 - "$tmpdir/out.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
width, height = struct.unpack('>II', data[16:24])
assert (width, height) == (32, 32), (width, height)
PY
