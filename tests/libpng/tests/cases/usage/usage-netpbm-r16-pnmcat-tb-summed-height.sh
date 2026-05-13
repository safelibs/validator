#!/usr/bin/env bash
# @testcase: usage-netpbm-r16-pnmcat-tb-summed-height
# @title: netpbm pnmcat -tb concatenates two PNG-derived PPMs to summed height
# @description: Builds two 4x3 PPMs, round-trips them through pnmtopng/pngtopnm, concatenates top-to-bottom with pnmcat -tb, and asserts the result reports width 4 and height 6 (sum of inputs) via pamfile.
# @timeout: 120
# @tags: usage, png, netpbm, pnmcat
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/a.ppm" "$tmpdir/b.ppm" <<'PY'
import sys
W, H = 4, 3
def write(path, base):
    b = bytearray()
    for y in range(H):
        for x in range(W):
            b += bytes((base + x, base + y, 90))
    open(path, 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
write(sys.argv[1], 5)
write(sys.argv[2], 200)
PY

pnmtopng "$tmpdir/a.ppm" >"$tmpdir/a.png"
pnmtopng "$tmpdir/b.ppm" >"$tmpdir/b.png"
pngtopnm "$tmpdir/a.png" >"$tmpdir/a2.ppm"
pngtopnm "$tmpdir/b.png" >"$tmpdir/b2.ppm"

pnmcat -tb "$tmpdir/a2.ppm" "$tmpdir/b2.ppm" >"$tmpdir/cat.ppm"

pamfile "$tmpdir/cat.ppm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'width 4'
validator_assert_contains "$tmpdir/info.txt" 'height 6'
