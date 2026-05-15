#!/usr/bin/env bash
# @testcase: usage-netpbm-r19-pngtopnm-grayscale-shape
# @title: netpbm pngtopnm decodes an 8-bit grayscale PNG into a P5 PGM of matching dimensions
# @description: Builds an 8x4 PGM, encodes to PNG via pnmtopng, decodes via pngtopnm, and asserts pamfile reports "PGM raw" and "8 by 4", pinning the libpng-backed grayscale-channel decode shape.
# @timeout: 120
# @tags: usage, png, netpbm, pngtopnm, grayscale, r19
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pgm" <<'PY'
import sys
W, H = 8, 4
b = bytearray()
for y in range(H):
    for x in range(W):
        b.append(((x + y) * 17) & 0xff)
open(sys.argv[1], 'wb').write(f'P5\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" >"$tmpdir/out.pgm"

pamfile "$tmpdir/out.pgm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'PGM raw'
validator_assert_contains "$tmpdir/info.txt" '8 by 4'
