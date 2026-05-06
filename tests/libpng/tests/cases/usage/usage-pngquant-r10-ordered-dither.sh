#!/usr/bin/env bash
# @testcase: usage-pngquant-r10-ordered-dither
# @title: pngquant --ordered selects the deterministic dither mode
# @description: Quantizes a synthetic PNG with --ordered (the alternative to Floyd-Steinberg) and verifies the optimized PNG is produced and remains structurally valid.
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

pngquant --ordered --force --output "$tmpdir/out.png" 64 "$tmpdir/in.png"

[[ -s "$tmpdir/out.png" ]]
file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'

python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n', data[:8]
PY
