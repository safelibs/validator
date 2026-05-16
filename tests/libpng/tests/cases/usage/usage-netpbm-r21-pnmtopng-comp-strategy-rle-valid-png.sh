#!/usr/bin/env bash
# @testcase: usage-netpbm-r21-pnmtopng-comp-strategy-rle-valid-png
# @title: netpbm pnmtopng -comp_strategy filtered emits a valid PNG with magic header
# @description: Encodes a P6 PPM via pnmtopng -comp_strategy filtered and asserts the output begins with the PNG 8-byte signature and contains an IHDR chunk, pinning that libpng accepts the "filtered" zlib strategy via netpbm's -comp_strategy option.
# @timeout: 120
# @tags: usage, png, netpbm, pnmtopng, compstrategy, r21
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 8, 6
body = bytearray()
for y in range(H):
    for x in range(W):
        body += bytes((x * 30 % 256, y * 30 % 256, 128))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + body)
PY

pnmtopng -comp_strategy filtered "$tmpdir/in.ppm" >"$tmpdir/out.png"
python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
assert b'IHDR' in data[:32]
PY
