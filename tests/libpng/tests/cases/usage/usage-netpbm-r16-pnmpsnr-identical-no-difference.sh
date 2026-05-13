#!/usr/bin/env bash
# @testcase: usage-netpbm-r16-pnmpsnr-identical-no-difference
# @title: netpbm pnmpsnr on a PNG-derived self-comparison reports no difference
# @description: Builds a synthetic 8x8 PNG, decodes to PPM twice via pngtopnm, runs pnmpsnr on the two byte-identical PNMs, and asserts the captured diagnostic contains "no difference" — pinning Ubuntu 24.04 netpbm's identical-image report.
# @timeout: 120
# @tags: usage, png, netpbm, pnmpsnr
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
        b += bytes((x * 32, y * 32, 64))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" >"$tmpdir/a.ppm"
cp "$tmpdir/a.ppm" "$tmpdir/b.ppm"

pnmpsnr "$tmpdir/a.ppm" "$tmpdir/b.ppm" >"$tmpdir/out.txt" 2>&1 || true
validator_assert_contains "$tmpdir/out.txt" 'no difference'
