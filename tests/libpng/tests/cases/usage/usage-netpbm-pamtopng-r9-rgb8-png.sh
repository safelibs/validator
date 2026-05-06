#!/usr/bin/env bash
# @testcase: usage-netpbm-pamtopng-r9-rgb8-png
# @title: pamtopng RGB 8-bit PAM
# @description: Builds an RGB 8-bit PAM and converts it via pamtopng, verifying the output IHDR reports color type 2 (truecolor) and bit depth 8.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pam" <<'PY'
import sys
w, h = 6, 4
with open(sys.argv[1], "wb") as f:
    hdr = f"P7\nWIDTH {w}\nHEIGHT {h}\nDEPTH 3\nMAXVAL 255\nTUPLTYPE RGB\nENDHDR\n"
    f.write(hdr.encode())
    f.write(b"".join(bytes([x * 40 % 256, y * 60 % 256, (x + y) * 20 % 256])
                     for y in range(h) for x in range(w)))
PY

pamtopng "$tmpdir/in.pam" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], "rb").read()
bit_depth = data[24]
color_type = data[25]
if (bit_depth, color_type) != (8, 2):
    raise SystemExit(f"expected (8, 2), got ({bit_depth}, {color_type})")
PY
