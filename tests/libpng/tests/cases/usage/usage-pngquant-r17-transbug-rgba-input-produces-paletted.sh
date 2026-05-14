#!/usr/bin/env bash
# @testcase: usage-pngquant-r17-transbug-rgba-input-produces-paletted
# @title: pngquant --transbug on an RGBA gradient PNG produces a paletted PNG
# @description: Generates a 32x32 PAM with alpha, encodes to PNG via pamtopng, runs pngquant --transbug, and asserts the output PNG has color type 3 (paletted), exercising the --transbug code path on RGBA input.
# @timeout: 120
# @tags: usage, image, png, pngquant, transbug
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pam" <<'PY'
import sys
W, H = 32, 32
header = (
    f'P7\nWIDTH {W}\nHEIGHT {H}\nDEPTH 4\nMAXVAL 255\n'
    f'TUPLTYPE RGB_ALPHA\nENDHDR\n'
).encode()
body = bytearray()
for y in range(H):
    for x in range(W):
        body += bytes(((x * 7) & 0xff, (y * 9) & 0xff, ((x + y) * 5) & 0xff, 200))
open(sys.argv[1], 'wb').write(header + body)
PY

pamtopng "$tmpdir/in.pam" >"$tmpdir/in.png"

pngquant --force --transbug --output "$tmpdir/out.png" 64 "$tmpdir/in.png"
validator_require_file "$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (32, 32), (w, h)
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY
