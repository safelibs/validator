#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-r9-grayscale-png
# @title: pnmtopng grayscale PGM color type
# @description: Encodes a PGM grayscale ramp and verifies the resulting PNG IHDR carries color type 0 (grayscale).
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pgm" <<'PY'
import sys
w, h = 16, 8
with open(sys.argv[1], "wb") as f:
    f.write(f"P5\n{w} {h}\n255\n".encode())
    f.write(bytes((x * 16) & 0xff for y in range(h) for x in range(w)))
PY

pnmtopng "$tmpdir/in.pgm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], "rb").read()
# IHDR color type byte is at offset 25 (signature 8 + length 4 + 'IHDR' 4 + width 4 + height 4 + bitdepth 1).
ct = data[25]
if ct != 0:
    raise SystemExit(f"expected grayscale (0), got color type {ct}")
PY
