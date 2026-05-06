#!/usr/bin/env bash
# @testcase: usage-netpbm-r11-pnmtopng-interlace-flag
# @title: netpbm pnmtopng -interlace sets IHDR Adam7 flag
# @description: Encodes a synthetic PPM with pnmtopng -interlace and confirms the resulting PNG IHDR interlace byte is 1 (Adam7) while the default encoding uses byte 0.
# @timeout: 120
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 16, 16
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 16, y * 16, ((x + y) * 8) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/plain.png"
pnmtopng -interlace "$tmpdir/in.ppm" >"$tmpdir/inter.png"

python3 - "$tmpdir/plain.png" "$tmpdir/inter.png" <<'PY'
import sys
plain = open(sys.argv[1], 'rb').read()
inter = open(sys.argv[2], 'rb').read()
assert plain[:8] == b'\x89PNG\r\n\x1a\n', plain[:8]
assert inter[:8] == b'\x89PNG\r\n\x1a\n', inter[:8]
# IHDR data sits at bytes 16..28; interlace flag is byte 28.
assert plain[28] == 0, plain[28]
assert inter[28] == 1, inter[28]
PY
