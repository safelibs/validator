#!/usr/bin/env bash
# @testcase: usage-netpbm-r17-pamfile-reports-ppm-raw-string
# @title: netpbm pamfile reports "PPM raw" on a libpng-derived color PPM
# @description: Decodes a PNG to PPM with pngtopnm and asserts pamfile output contains the literal "PPM raw" magic-type descriptor, pinning the Ubuntu 24.04 netpbm pamfile schema string.
# @timeout: 120
# @tags: usage, png, netpbm, pamfile
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 4, 4
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 50, y * 50, 100))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/mid.png"
pngtopnm "$tmpdir/mid.png" >"$tmpdir/out.ppm"

pamfile "$tmpdir/out.ppm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'PPM raw'
