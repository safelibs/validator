#!/usr/bin/env bash
# @testcase: usage-netpbm-r19-pamarith-subtract-png-roundtrip-dims
# @title: netpbm pamarith -subtract on two PNG-derived PPMs preserves dimensions
# @description: Encodes two 7x5 PPMs to PNG via pnmtopng, decodes back to PPM with pngtopnm, runs pamarith -subtract on the pair, and asserts pamfile reports "7 by 5", pinning libpng-mediated pixel-arithmetic dimensions.
# @timeout: 120
# @tags: usage, png, netpbm, pamarith, subtract, r19
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/a.ppm" 100 <<'PY'
import sys
W, H = 7, 5
v = int(sys.argv[2])
b = bytes((v, v, v)) * (W * H)
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
python3 - "$tmpdir/b.ppm" 30 <<'PY'
import sys
W, H = 7, 5
v = int(sys.argv[2])
b = bytes((v, v, v)) * (W * H)
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/a.ppm" >"$tmpdir/a.png"
pnmtopng "$tmpdir/b.ppm" >"$tmpdir/b.png"

pngtopnm "$tmpdir/a.png" >"$tmpdir/a-r.ppm"
pngtopnm "$tmpdir/b.png" >"$tmpdir/b-r.ppm"

pamarith -subtract "$tmpdir/a-r.ppm" "$tmpdir/b-r.ppm" >"$tmpdir/diff.ppm"
pamfile "$tmpdir/diff.ppm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '7 by 5'
