#!/usr/bin/env bash
# @testcase: usage-netpbm-r18-pamcut-window-dims
# @title: netpbm pamcut -left -top -width -height carves a 3x3 window from a PNG-decoded PPM
# @description: Encodes an 8x8 PPM to PNG with pnmtopng, decodes with pngtopnm, then runs pamcut -left 2 -top 1 -width 3 -height 3 and asserts pamfile reports a "3 by 3" sub-image, exercising netpbm sub-region selection through a libpng round trip.
# @timeout: 120
# @tags: usage, png, netpbm, pamcut, r18
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
        b += bytes(((x * 20) & 0xff, (y * 25) & 0xff, 70))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" | pamcut -left 2 -top 1 -width 3 -height 3 >"$tmpdir/out.ppm"

pamfile "$tmpdir/out.ppm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '3 by 3'
