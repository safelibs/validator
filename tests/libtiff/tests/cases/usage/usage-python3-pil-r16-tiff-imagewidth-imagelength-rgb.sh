#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-tiff-imagewidth-imagelength-rgb
# @title: PIL RGB TIFF surfaces ImageWidth (256) and ImageLength (257) tags matching saved dimensions
# @description: Saves a 19x13 RGB TIFF with Pillow, reopens with Pillow, asserts tag_v2[256] equals 19 and tag_v2[257] equals 13, and asserts info or the image size matches the same dimensions — exercising libtiff's width/length tags through Pillow's reader.
# @timeout: 60
# @tags: usage, tiff, python, tag, dimensions
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/wxh.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

w, h = 19, 13
Image.new('RGB', (w, h), (200, 100, 50)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.size == (w, h), ('size', im.size)
    tw = im.tag_v2.get(256)
    tl = im.tag_v2.get(257)
    assert tw == w, ('imagewidth', tw)
    assert tl == h, ('imagelength', tl)
PY
