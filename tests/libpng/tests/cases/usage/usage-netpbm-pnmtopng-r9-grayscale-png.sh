#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-r9-grayscale-png
# @title: pnmtopng grayscale PGM stays non-truecolor
# @description: Encodes a PGM grayscale ramp and verifies the resulting PNG IHDR carries a non-truecolor color type (0 grayscale or 3 palette), proving pnmtopng didn't expand to RGB.
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
# 0 = grayscale, 3 = palette. Either one is a valid lossless representation
# of an 8-bit PGM source; we just want to confirm pnmtopng did not expand to
# truecolor RGB (2) or RGBA (6).
if ct not in (0, 3):
    raise SystemExit(f"expected grayscale (0) or palette (3), got color type {ct}")
PY
