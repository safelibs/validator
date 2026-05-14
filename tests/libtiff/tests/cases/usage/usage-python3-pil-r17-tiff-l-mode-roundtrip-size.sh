#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-tiff-l-mode-roundtrip-size
# @title: Pillow grayscale ("L") TIFF round-trips dimensions and mode
# @description: Writes an 11x7 grayscale "L" mode TIFF with Pillow, reopens it, asserts the mode is exactly "L" and the size tuple equals (11, 7), confirming libtiff's MinIsBlack grayscale single-sample round-trip via Pillow.
# @timeout: 60
# @tags: usage, tiff, python, grayscale, r17
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/lmode.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
img = Image.new('L', (11, 7), 128)
img.save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'L', ('mode', im.mode)
    assert im.size == (11, 7), ('size', im.size)
print('ok L 11x7')
PY
