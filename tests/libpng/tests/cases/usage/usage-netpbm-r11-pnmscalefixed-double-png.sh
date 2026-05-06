#!/usr/bin/env bash
# @testcase: usage-netpbm-r11-pnmscalefixed-double-png
# @title: netpbm pnmscalefixed 2 doubles PNG-derived dimensions
# @description: Decodes a synthetic PNG to PAM, scales it 2x with pnmscalefixed (fixed-point integer scaling), and re-encodes via pnmtopng, verifying the output PNG geometry is exactly twice the input.
# @timeout: 120
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 16, 12
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 16) & 0xff, (y * 20) & 0xff, ((x + y) * 8) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngtopam "$tmpdir/in.png" | pnmscalefixed 2 | pnmtopng >"$tmpdir/big.png"

file "$tmpdir/big.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
validator_assert_contains "$tmpdir/file.txt" '32 x 24'

python3 - "$tmpdir/big.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
width, height = struct.unpack('>II', data[16:24])
assert (width, height) == (32, 24), (width, height)
PY
