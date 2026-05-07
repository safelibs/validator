#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-tiff-mode-f-float-half-pixel-roundtrip
# @title: PIL mode "F" TIFF retains a fractional 0.5 pixel value on reload
# @description: Writes a Pillow mode "F" (float32) TIFF whose every pixel is 0.5 and verifies the reopened image's mode is "F" and getpixel((1,1)) is exactly 0.5 (well-represented in IEEE-754 float32), asserting libtiff carries float32 sample values through Pillow's mode "F" round-trip without rounding to integer.
# @timeout: 60
# @tags: usage, tiff, python, f-mode, float
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/f-mode.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('F', (6, 6), 0.5).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'F', ('mode', im.mode)
    px = im.getpixel((1, 1))
    assert px == 0.5, ('pixel', px)
PY
