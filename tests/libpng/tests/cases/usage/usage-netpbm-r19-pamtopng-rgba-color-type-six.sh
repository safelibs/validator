#!/usr/bin/env bash
# @testcase: usage-netpbm-r19-pamtopng-rgba-color-type-six
# @title: netpbm pamtopng on an RGB_ALPHA PAM emits IHDR color type 6
# @description: Builds a 12x12 PAM with TUPLTYPE RGB_ALPHA, encodes via pamtopng, and asserts the IHDR color type byte is 6 (RGBA), pinning that the libpng encoder selects the correct color type for alpha-bearing PAM input.
# @timeout: 120
# @tags: usage, png, netpbm, pamtopng, rgba, r19
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pam" <<'PY'
import sys
W, H = 12, 12
header = (
    f'P7\nWIDTH {W}\nHEIGHT {H}\nDEPTH 4\nMAXVAL 255\n'
    f'TUPLTYPE RGB_ALPHA\nENDHDR\n'
).encode()
body = bytearray()
for y in range(H):
    for x in range(W):
        body += bytes(((x * 11) & 0xff, (y * 13) & 0xff, ((x + y) * 7) & 0xff, 128))
open(sys.argv[1], 'wb').write(header + body)
PY

pamtopng "$tmpdir/in.pam" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (12, 12), (w, h)
assert ctype == 6, f'expected color type 6 (RGBA), got {ctype}'
PY
