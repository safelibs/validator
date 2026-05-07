#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-tiff-mode-i-int32-pixel-roundtrip
# @title: PIL mode "I" (int32) TIFF retains a 100000 pixel value on reload
# @description: Writes a Pillow mode "I" (int32 signed) TIFF whose every pixel is 100000 (well outside the 16-bit range) and verifies the reopened image's mode begins with "I" and getpixel((2,2)) returns 100000 unchanged, asserting libtiff carries 32-bit integer samples without truncating to 16 or 8 bits.
# @timeout: 60
# @tags: usage, tiff, python, i-mode, int32
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/i-mode.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('I', (8, 8), 100000).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode.startswith('I'), ('mode', im.mode)
    px = im.getpixel((2, 2))
    assert px == 100000, ('pixel', px)
PY
