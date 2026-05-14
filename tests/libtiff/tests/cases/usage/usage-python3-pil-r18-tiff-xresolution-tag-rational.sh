#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-tiff-xresolution-tag-rational
# @title: Pillow TIFF XResolution tag 282 reports a positive rational equivalent to the saved DPI
# @description: Saves a TIFF with dpi=(150, 150), reopens it with Pillow, asserts tag_v2[282] (XResolution) is a libtiff rational castable to a positive float equal to 150.0, and asserts tag_v2[283] (YResolution) is also castable to 150.0, confirming libtiff RATIONAL-typed tag round-trip via Pillow.
# @timeout: 60
# @tags: usage, tiff, python, xresolution, dpi, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/xres.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (4, 4)).save(sys.argv[1], 'TIFF', dpi=(150, 150))

with Image.open(sys.argv[1]) as im:
    im.load()
    xv = float(im.tag_v2.get(282))
    yv = float(im.tag_v2.get(283))
    assert xv == 150.0, ('x', xv)
    assert yv == 150.0, ('y', yv)
print('ok xres=%g yres=%g' % (xv, yv))
PY
