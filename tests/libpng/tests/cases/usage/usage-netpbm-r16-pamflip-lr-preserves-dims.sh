#!/usr/bin/env bash
# @testcase: usage-netpbm-r16-pamflip-lr-preserves-dims
# @title: netpbm pamflip -lr on a PNG preserves width and height in pamfile output
# @description: Flips a 6x4 PNG horizontally through pngtopam | pamflip -lr | pamtopng, decodes the result, and asserts pamfile reports the same width (6) and height (4) on the flipped image — confirming horizontal mirror is dimension-preserving.
# @timeout: 120
# @tags: usage, png, netpbm, pamflip
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 6, 4
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 16, y * 24, 128))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngtopam "$tmpdir/in.png" | pamflip -lr | pamtopng >"$tmpdir/out.png"
pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"

pamfile "$tmpdir/out.pam" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'width 6'
validator_assert_contains "$tmpdir/info.txt" 'height 4'
