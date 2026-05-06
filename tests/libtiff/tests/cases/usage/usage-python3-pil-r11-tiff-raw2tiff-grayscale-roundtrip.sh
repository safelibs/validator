#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-tiff-raw2tiff-grayscale-roundtrip
# @title: raw2tiff wraps an 8-bit grayscale buffer with declared geometry
# @description: Writes a deterministic 20x15 byte ramp to a raw file, runs raw2tiff with -w 20 -l 15 -b 1 -d byte, and verifies tiffinfo reports the exact ImageWidth/ImageLength and 8 bits-per-sample on the produced TIFF.
# @timeout: 60
# @tags: usage, tiff, raw2tiff, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.raw" <<'PY'
import sys
data = bytes((i % 256) for i in range(20 * 15))
open(sys.argv[1], 'wb').write(data)
PY

raw2tiff -w 20 -l 15 -b 1 -d byte "$tmpdir/in.raw" "$tmpdir/out.tif" >"$tmpdir/raw2tiff.out" 2>&1

tiffinfo "$tmpdir/out.tif" >"$tmpdir/info.out"
grep -E 'Image Width: 20 Image Length: 15' "$tmpdir/info.out" >/dev/null
grep -E 'Bits/Sample: 8' "$tmpdir/info.out" >/dev/null
grep -E 'Samples/Pixel: 1' "$tmpdir/info.out" >/dev/null
