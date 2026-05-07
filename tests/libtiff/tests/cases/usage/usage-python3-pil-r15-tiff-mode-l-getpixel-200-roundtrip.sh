#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-tiff-mode-l-getpixel-200-roundtrip
# @title: PIL mode "L" TIFF carries a 200 pixel value through getpixel after reopen
# @description: Writes a Pillow mode "L" TIFF whose every pixel is 200 (mid-bright 8-bit grayscale) and verifies the reopened image's mode is "L", size is preserved, and getpixel((3,1)) returns 200 unchanged, asserting libtiff round-trips 8-bit grayscale samples without value distortion.
# @timeout: 60
# @tags: usage, tiff, python, l-mode, grayscale
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/l-mode.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('L', (12, 6), 200).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'L', ('mode', im.mode)
    assert im.size == (12, 6), ('size', im.size)
    px = im.getpixel((3, 1))
    assert px == 200, ('pixel', px)
PY
