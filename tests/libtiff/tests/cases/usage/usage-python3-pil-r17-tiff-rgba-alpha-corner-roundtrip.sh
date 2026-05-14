#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-tiff-rgba-alpha-corner-roundtrip
# @title: Pillow RGBA TIFF preserves a distinct alpha value at the (0,0) corner across round-trip
# @description: Writes a 4x4 RGBA TIFF with the corner pixel (0,0) set to RGBA (10,20,30,40) and the rest opaque white, reopens with Pillow, asserts the reopened mode is "RGBA" and getpixel((0,0)) returns the same (10,20,30,40) tuple, confirming libtiff alpha-plane preservation.
# @timeout: 60
# @tags: usage, tiff, python, rgba, alpha, r17
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/rgba.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
img = Image.new('RGBA', (4, 4), (255, 255, 255, 255))
img.putpixel((0, 0), (10, 20, 30, 40))
img.save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'RGBA', ('mode', im.mode)
    assert im.getpixel((0, 0)) == (10, 20, 30, 40), ('px', im.getpixel((0, 0)))
print('ok rgba corner ok')
PY
