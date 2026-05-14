#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-tiff-mode-p-palette-roundtrip
# @title: Pillow palette ("P") TIFF round-trips and preserves the P mode on reopen
# @description: Constructs an 8x8 "P" mode palette image, saves it as a TIFF, reopens it with Pillow, and asserts the reopened image mode is exactly "P" with the same width and height, confirming libtiff palette pass-through and Pillow's TIFF palette decoding.
# @timeout: 60
# @tags: usage, tiff, python, palette, r17
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/palette.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
img = Image.new('P', (8, 8))
palette = []
for i in range(256):
    palette.extend([i, (i * 3) % 256, (i * 5) % 256])
img.putpalette(palette)
img.putdata([i % 256 for i in range(64)])
img.save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'P', ('mode', im.mode)
    assert im.size == (8, 8), ('size', im.size)
print('ok mode=P')
PY
