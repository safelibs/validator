#!/usr/bin/env bash
# @testcase: usage-netpbm-pamtopng-r9-rgb-alpha-png
# @title: pamtopng RGB_ALPHA PAM color type 6
# @description: Builds an RGB_ALPHA 4-channel PAM and converts via pamtopng, verifying the output PNG IHDR carries color type 6 (truecolor with alpha).
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pam" <<'PY'
import sys
w, h = 5, 3
with open(sys.argv[1], "wb") as f:
    hdr = f"P7\nWIDTH {w}\nHEIGHT {h}\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n"
    f.write(hdr.encode())
    f.write(b"".join(bytes([20 * x % 256, 30 * y % 256, (x + y) * 10 % 256, 128])
                     for y in range(h) for x in range(w)))
PY

pamtopng "$tmpdir/in.pam" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], "rb").read()
color_type = data[25]
if color_type != 6:
    raise SystemExit(f"expected truecolor+alpha (6), got {color_type}")
PY
