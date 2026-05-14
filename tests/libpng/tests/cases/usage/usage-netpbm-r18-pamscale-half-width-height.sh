#!/usr/bin/env bash
# @testcase: usage-netpbm-r18-pamscale-half-width-height
# @title: netpbm pamscale 0.5 halves both dimensions of a PNG-derived PPM
# @description: Builds an 8x8 PPM, encodes to PNG via pnmtopng, decodes via pngtopnm, scales by pamscale 0.5, and asserts pamfile reports "4 by 4" — exercising netpbm scaling through a libpng round trip.
# @timeout: 120
# @tags: usage, png, netpbm, pamscale, r18
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 8, 8
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 30) & 0xff, (y * 40) & 0xff, 60))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" | pamscale 0.5 >"$tmpdir/out.ppm"

pamfile "$tmpdir/out.ppm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '4 by 4'
