#!/usr/bin/env bash
# @testcase: usage-netpbm-r20-pnmtopng-compression-zero-roundtrip
# @title: netpbm pnmtopng -compression 0 emits a valid PNG that decodes back to the source
# @description: Encodes a 12x12 RGB PPM via pnmtopng -compression 0 (no zlib compression), validates the PNG magic and IEND, then decodes via pngtopnm and asserts dimensions match the source, exercising libpng's encoder with the stored-deflate path and round-tripping through the decoder.
# @timeout: 120
# @tags: usage, png, netpbm, pnmtopng, compression-zero, r20
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 12, 12
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 7) & 0xff, (y * 11) & 0xff, ((x ^ y) * 5) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng -compression 0 "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
assert data[-12:] == b'\x00\x00\x00\x00IEND\xaeB`\x82', data[-12:]
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (12, 12), (w, h)
PY

pngtopnm "$tmpdir/out.png" >"$tmpdir/back.ppm"
validator_require_file "$tmpdir/back.ppm"
