#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-tiff-yresolution-tag-rational
# @title: Pillow TIFF YResolution tag 283 round-trips an asymmetric dpi value
# @description: Saves an RGB TIFF with dpi=(96, 144) (asymmetric x/y resolution), reopens with Pillow, asserts tag_v2[282] (XResolution) is castable to 96.0 and tag_v2[283] (YResolution) is castable to 144.0, and asserts the two values differ, confirming libtiff persists independent rational X/Y resolution tags through a write+read cycle.
# @timeout: 60
# @tags: usage, tiff, python, yresolution, dpi, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/yres.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (4, 4)).save(sys.argv[1], 'TIFF', dpi=(96, 144))

with Image.open(sys.argv[1]) as im:
    im.load()
    xv = float(im.tag_v2.get(282))
    yv = float(im.tag_v2.get(283))
    assert xv == 96.0, ('x', xv)
    assert yv == 144.0, ('y', yv)
    assert xv != yv, ('expected x!=y', xv, yv)
print('ok yres=%g (x=%g)' % (yv, xv))
PY
