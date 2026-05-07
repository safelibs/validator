#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-tiff-f-mode-float-zero-readback
# @title: PIL F mode TIFF preserves a 0.5 float pixel through libtiff
# @description: Builds a Pillow mode "F" image filled with 0.5, saves it as TIFF, and verifies the reopened mode is "F", size is unchanged, and getpixel((0,0)) is exactly 0.5 (representable as float32), asserting libtiff stores 32-bit IEEE float samples without quantisation.
# @timeout: 60
# @tags: usage, tiff, python, float, f-mode
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/fmode.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
img = Image.new('F', (4, 3), 0.5)
img.save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'F', ('mode', im.mode)
    assert im.size == (4, 3), ('size', im.size)
    px = im.getpixel((0, 0))
    assert px == 0.5, ('pixel', px)
PY
