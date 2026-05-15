#!/usr/bin/env bash
# @testcase: usage-netpbm-r19-pamflip-tb-roundtrip-restores-png
# @title: netpbm pamflip top-bottom twice round-trips a PNG-derived PPM to identical bytes
# @description: Encodes a 6x6 PPM to PNG via pnmtopng, decodes back to PPM via pngtopnm, applies pamflip -tb twice and asserts the SHA-256 of the doubly-flipped PPM matches the original decoded PPM, pinning the flip-involutivity round trip across libpng.
# @timeout: 120
# @tags: usage, png, netpbm, pamflip, r19
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 6, 6
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 30) & 0xff, (y * 25) & 0xff, ((x + y) * 18) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" >"$tmpdir/decoded.ppm"

pamflip -tb "$tmpdir/decoded.ppm" | pamflip -tb >"$tmpdir/twice.ppm"

src=$(sha256sum "$tmpdir/decoded.ppm" | awk '{print $1}')
dst=$(sha256sum "$tmpdir/twice.ppm" | awk '{print $1}')
[[ "$src" == "$dst" ]]
