#!/usr/bin/env bash
# @testcase: usage-netpbm-r17-pamtopng-then-pngtopam-roundtrip-dims
# @title: netpbm pamtopng then pngtopam round-trip preserves dimensions
# @description: Converts a 6x5 PPM to PNG with pamtopng and back to PAM with pngtopam, then asserts pamfile reports "6 by 5" — verifying libpng-mediated dimension fidelity end-to-end.
# @timeout: 120
# @tags: usage, png, netpbm, roundtrip
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 6, 5
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 30) & 0xff, (y * 40) & 0xff, 80))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pamtopng "$tmpdir/in.ppm" >"$tmpdir/mid.png"
pngtopam "$tmpdir/mid.png" >"$tmpdir/out.pam"

pamfile "$tmpdir/out.pam" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '6 by 5'
