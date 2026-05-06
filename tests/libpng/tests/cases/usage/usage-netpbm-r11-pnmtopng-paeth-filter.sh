#!/usr/bin/env bash
# @testcase: usage-netpbm-r11-pnmtopng-paeth-filter
# @title: netpbm pnmtopng -filter=4 produces a valid PNG
# @description: Encodes a synthetic gradient PPM with pnmtopng -filter=4 (Paeth filter strategy) and verifies the output is a well-formed PNG, exercising the explicit filter selection path through libpng.
# @timeout: 120
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 32, 24
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 8 & 0xff, y * 10 & 0xff, ((x + y) * 5) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng -filter=4 "$tmpdir/in.ppm" >"$tmpdir/out.png"

file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'

python3 - "$tmpdir/out.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n', data[:8]
width, height = struct.unpack('>II', data[16:24])
assert (width, height) == (32, 24), (width, height)
PY
