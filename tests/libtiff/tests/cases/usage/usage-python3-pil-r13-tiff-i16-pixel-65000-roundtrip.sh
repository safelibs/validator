#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-tiff-i16-pixel-65000-roundtrip
# @title: PIL I;16 TIFF retains a 65000 pixel value on reload
# @description: Writes a Pillow I;16 grayscale TIFF whose every pixel is 65000 (near the 16-bit ceiling) and verifies the reopened image's mode is "I;16" and getpixel((4,2)) returns 65000 unchanged, asserting libtiff carries 16-bit grayscale samples without 8-bit truncation.
# @timeout: 60
# @tags: usage, tiff, python, sixteen-bit, grayscale
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/i16-high.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('I;16', (10, 6), 65000).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'I;16', ('mode', im.mode)
    assert im.size == (10, 6), ('size', im.size)
    px = im.getpixel((4, 2))
    assert px == 65000, ('pixel', px)
PY
