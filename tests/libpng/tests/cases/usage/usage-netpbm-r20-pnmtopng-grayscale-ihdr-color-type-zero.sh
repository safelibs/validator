#!/usr/bin/env bash
# @testcase: usage-netpbm-r20-pnmtopng-grayscale-ihdr-color-type-zero
# @title: netpbm pnmtopng on a P5 PGM emits IHDR color type 0 (grayscale)
# @description: Builds a 12x12 P5 grayscale PGM, encodes via pnmtopng, and asserts the IHDR color type byte is 0 (grayscale, no alpha) and the bit depth is 8, exercising libpng's encoder color-type selection for plain grayscale inputs.
# @timeout: 120
# @tags: usage, png, netpbm, pnmtopng, grayscale, r20
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pgm" <<'PY'
import sys
W, H = 12, 12
hdr = f'P5\n{W} {H}\n255\n'.encode()
body = bytes(((x + y) * 7) & 0xff for y in range(H) for x in range(W))
open(sys.argv[1], 'wb').write(hdr + body)
PY

pnmtopng "$tmpdir/in.pgm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (12, 12), (w, h)
assert depth == 8, depth
assert ctype == 0, f'expected color type 0 (grayscale), got {ctype}'
PY
