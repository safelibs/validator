#!/usr/bin/env bash
# @testcase: usage-netpbm-ppmtoyuv-png
# @title: netpbm ppmtoyuv from PNG-derived ppm
# @description: Decodes the basn2c08 PNG fixture to a ppm and converts it to YUV via ppmtoyuv, then verifies the YUV byte count matches the 4:2:2 Abekas layout for 32x32.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/in.ppm"

pamfile "$tmpdir/in.ppm" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '32 by 32'

ppmtoyuv "$tmpdir/in.ppm" >"$tmpdir/out.yuv"

# Netpbm's ppmtoyuv emits Abekas YUV (4:2:2): Y plane = w*h, plus U and V
# subsampled horizontally to w/2 over the full height, so the total is
# w*h + 2*(w/2)*h = 2*w*h. For 32x32 this is 2048 bytes.
python3 - "$tmpdir/out.yuv" <<'PY'
import sys, os
size = os.path.getsize(sys.argv[1])
w, h = 32, 32
expected = w * h + 2 * (w // 2) * h
if size != expected:
    raise SystemExit(f'expected {expected} YUV bytes, got {size}')
data = open(sys.argv[1], 'rb').read()
if len(set(data)) < 2:
    raise SystemExit('expected non-uniform YUV output')
PY
