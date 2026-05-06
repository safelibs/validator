#!/usr/bin/env bash
# @testcase: usage-netpbm-pngtopnm-r9-color-decode
# @title: pngtopnm decodes solid blue PNG
# @description: Encodes a solid blue 4x4 RGB PNG via pnmtopng then decodes it back with pngtopnm and verifies the resulting PPM payload contains the expected (0,0,255) pixel triplets.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/blue.ppm" <<'PY'
import sys
w, h = 4, 4
with open(sys.argv[1], "wb") as f:
    f.write(f"P6\n{w} {h}\n255\n".encode())
    f.write(b"\x00\x00\xff" * (w * h))
PY

pnmtopng "$tmpdir/blue.ppm" >"$tmpdir/blue.png"
pngtopnm "$tmpdir/blue.png" >"$tmpdir/out.ppm"

python3 - "$tmpdir/out.ppm" <<'PY'
import sys
data = open(sys.argv[1], "rb").read()
# Skip the netpbm header (3 ASCII tokens + newlines).
nl = 0
i = 0
while nl < 3:
    if data[i:i+1] == b"\n":
        nl += 1
    i += 1
pixels = data[i:]
assert pixels == b"\x00\x00\xff" * 16, pixels[:16]
PY
