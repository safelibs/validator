#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-tiff-mode-i16-getextrema-tuple
# @title: Pillow I;16 mode TIFF getextrema returns (min, max) tuple over 16-bit pixel range
# @description: Constructs an I;16 image from raw little-endian bytes containing the four values 0, 1, 30000, and 65535, saves it as TIFF, reopens, and asserts getextrema() returns exactly (0, 65535), exercising libtiff 16-bit grayscale decoding plus Pillow's per-mode min/max computation.
# @timeout: 60
# @tags: usage, tiff, python, i16, extrema, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/i16.tif" <<'PY'
import sys
import struct
from PIL import Image

pixels = struct.pack('<HHHH', 0, 1, 30000, 65535)
im = Image.frombytes('I;16', (2, 2), pixels)
im.save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as r:
    r.load()
    assert r.mode == 'I;16', r.mode
    lo, hi = r.getextrema()
    assert lo == 0 and hi == 65535, (lo, hi)
    print('ok extrema=(%d,%d)' % (lo, hi))
PY
