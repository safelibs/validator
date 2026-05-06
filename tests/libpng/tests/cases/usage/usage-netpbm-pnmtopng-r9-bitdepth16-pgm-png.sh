#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-r9-bitdepth16-pgm-png
# @title: pnmtopng 16-bit PGM input
# @description: Encodes a 16-bit PGM through pnmtopng and verifies the resulting PNG IHDR carries bit depth 16 and color type 0.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pgm" <<'PY'
import sys, struct
w, h = 8, 4
with open(sys.argv[1], "wb") as f:
    f.write(f"P5\n{w} {h}\n65535\n".encode())
    samples = []
    for y in range(h):
        for x in range(w):
            samples.append(struct.pack(">H", (x * 8000 + y * 1000) & 0xffff))
    f.write(b"".join(samples))
PY

pnmtopng "$tmpdir/in.pgm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], "rb").read()
bit_depth = data[24]
color_type = data[25]
if (bit_depth, color_type) != (16, 0):
    raise SystemExit(f"expected (16, 0), got ({bit_depth}, {color_type})")
PY
