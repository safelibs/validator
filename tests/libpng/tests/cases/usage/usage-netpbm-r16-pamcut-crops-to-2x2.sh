#!/usr/bin/env bash
# @testcase: usage-netpbm-r16-pamcut-crops-to-2x2
# @title: netpbm pamcut crops a PNG-derived PAM to a 2x2 region
# @description: Decodes a 4x4 PNG to PAM, crops with pamcut -left 1 -top 1 -width 2 -height 2, and asserts the cropped PAM reports width 2 and height 2 via pamfile.
# @timeout: 120
# @tags: usage, png, netpbm, pamcut
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
        b += bytes((x * 60, y * 60, 100))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngtopam "$tmpdir/in.png" | pamcut -left 1 -top 1 -width 2 -height 2 >"$tmpdir/out.pam"

pamfile "$tmpdir/out.pam" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'width 2'
validator_assert_contains "$tmpdir/info.txt" 'height 2'
