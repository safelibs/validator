#!/usr/bin/env bash
# @testcase: usage-pngquant-r9-quality-bounds-zero
# @title: pngquant quality 0-100 emits valid PNG
# @description: Quantizes a synthetic PNG at the maximally permissive quality range 0-100 and verifies the output is a valid PNG file.
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
        b += bytes(((x * 8) & 0xff, (y * 8) & 0xff, (x ^ y) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --quality=0-100 --force --output "$tmpdir/out.png" 256 "$tmpdir/in.png"
file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
