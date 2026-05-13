#!/usr/bin/env bash
# @testcase: usage-netpbm-r16-pnmcat-lr-summed-width
# @title: netpbm pnmcat -lr concatenates two PNG-derived PPMs to summed width
# @description: Builds two 3x2 PPMs, converts to PNG and back, concatenates left-to-right with pnmcat -lr, and asserts the resulting PPM reports width 6 via pamfile while preserving height 2.
# @timeout: 120
# @tags: usage, png, netpbm, pnmcat
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/a.ppm" "$tmpdir/b.ppm" <<'PY'
import sys
W, H = 3, 2
def write(path, base):
    b = bytearray()
    for y in range(H):
        for x in range(W):
            b += bytes((base + x, base + y, 100))
    open(path, 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
write(sys.argv[1], 10)
write(sys.argv[2], 80)
PY

pnmtopng "$tmpdir/a.ppm" >"$tmpdir/a.png"
pnmtopng "$tmpdir/b.ppm" >"$tmpdir/b.png"
pngtopnm "$tmpdir/a.png" >"$tmpdir/a2.ppm"
pngtopnm "$tmpdir/b.png" >"$tmpdir/b2.ppm"

pnmcat -lr "$tmpdir/a2.ppm" "$tmpdir/b2.ppm" >"$tmpdir/cat.ppm"

pamfile "$tmpdir/cat.ppm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'width 6'
validator_assert_contains "$tmpdir/info.txt" 'height 2'
