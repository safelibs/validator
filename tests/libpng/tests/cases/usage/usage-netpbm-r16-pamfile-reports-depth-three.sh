#!/usr/bin/env bash
# @testcase: usage-netpbm-r16-pamfile-reports-depth-three
# @title: netpbm pamfile reports depth 3 for a generated RGB PPM
# @description: Generates a 4x2 P6 PPM in shell, converts to PAM with pnmtopam (via pngtopam round trip), then runs pamfile and asserts the captured output contains "depth 3" — pinning the depth field for a 3-channel raster.
# @timeout: 120
# @tags: usage, png, netpbm, pamfile
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 4, 2
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 32, y * 64, 200))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngtopam "$tmpdir/in.png" >"$tmpdir/out.pam"

pamfile "$tmpdir/out.pam" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'depth 3'
validator_assert_contains "$tmpdir/info.txt" 'width 4'
