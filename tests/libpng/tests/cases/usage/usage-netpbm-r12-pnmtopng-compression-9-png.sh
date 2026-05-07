#!/usr/bin/env bash
# @testcase: usage-netpbm-r12-pnmtopng-compression-9-png
# @title: netpbm pnmtopng -compression=9 produces a valid PNG
# @description: Encodes a synthetic 32x32 PPM with pnmtopng -compression=9 (maximum zlib level) and verifies the output is a well-formed PNG with the expected geometry, exercising the high-compression code path through libpng.
# @timeout: 120
# @tags: usage, png, netpbm, compression
# @client: netpbm

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

pnmtopng -compression=9 "$tmpdir/in.ppm" >"$tmpdir/out.png"

file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
validator_assert_contains "$tmpdir/file.txt" '32 x 32'

python3 - "$tmpdir/out.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n', data[:8]
width, height = struct.unpack('>II', data[16:24])
assert (width, height) == (32, 32), (width, height)
PY
