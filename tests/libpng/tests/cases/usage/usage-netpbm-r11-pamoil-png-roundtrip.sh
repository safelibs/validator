#!/usr/bin/env bash
# @testcase: usage-netpbm-r11-pamoil-png-roundtrip
# @title: netpbm pamoil oil-paint preserves geometry through PNG encode
# @description: Decodes a synthetic PNG to PAM, applies pamoil's oil-paint stylisation, and re-encodes via pnmtopng, confirming the output PNG retains the original 32x24 dimensions and color type.
# @timeout: 180
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
        b += bytes(((x * 8) & 0xff, (y * 10) & 0xff, ((x ^ y) * 6) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngtopam "$tmpdir/in.png" | pamoil | pnmtopng >"$tmpdir/oil.png"

file "$tmpdir/oil.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
validator_assert_contains "$tmpdir/file.txt" '32 x 24'

python3 - "$tmpdir/oil.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
width, height, _, color_type = struct.unpack('>IIBB', data[16:26])
assert (width, height) == (32, 24), (width, height)
assert color_type in (2, 3), color_type  # truecolor or palette
PY
