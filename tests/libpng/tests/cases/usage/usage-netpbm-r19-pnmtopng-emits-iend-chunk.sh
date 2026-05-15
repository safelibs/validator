#!/usr/bin/env bash
# @testcase: usage-netpbm-r19-pnmtopng-emits-iend-chunk
# @title: netpbm pnmtopng output terminates with a proper IEND chunk
# @description: Encodes a 5x5 PPM to PNG via pnmtopng and asserts the final 12 bytes match the canonical IEND chunk (length 0, type "IEND", CRC 0xae426082), pinning the libpng end-of-stream marker exactly.
# @timeout: 120
# @tags: usage, png, netpbm, iend, r19
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 5, 5
b = bytes((40, 80, 120)) * (W * H)
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
expected = b'\x00\x00\x00\x00IEND\xae\x42\x60\x82'
assert data[-12:] == expected, data[-12:].hex()
PY
