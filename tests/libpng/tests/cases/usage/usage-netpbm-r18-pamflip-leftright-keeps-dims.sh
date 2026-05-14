#!/usr/bin/env bash
# @testcase: usage-netpbm-r18-pamflip-leftright-keeps-dims
# @title: netpbm pamflip -leftright preserves dimensions through a libpng round trip
# @description: Builds a 5x3 PPM, encodes to PNG via pnmtopng, decodes and flips left-right with pamflip, and asserts pamfile reports "5 by 3" — exercising libpng-mediated geometry preservation under flip.
# @timeout: 120
# @tags: usage, png, netpbm, pamflip, r18
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 5, 3
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 50) & 0xff, (y * 80) & 0xff, 90))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" | pamflip -leftright >"$tmpdir/out.ppm"

pamfile "$tmpdir/out.ppm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '5 by 3'
