#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-16bit-grayscale-pixel-roundtrip
# @title: PIL I;16 TIFF preserves a 40000 pixel value through libtiff write/read
# @description: Saves an I;16 grayscale TIFF whose every pixel is 40000 and verifies the reopened image's mode is 'I;16' and getpixel((0,0)) returns 40000 unchanged, asserting libtiff stores 16-bit grayscale samples without truncation to 8 bits.
# @timeout: 60
# @tags: usage, tiff, python, sixteen-bit, grayscale
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/g16.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('I;16', (12, 8), 40000).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'I;16', ('mode', im.mode)
    assert im.size == (12, 8), ('size', im.size)
    px = im.getpixel((0, 0))
    assert px == 40000, ('pixel', px)
PY
