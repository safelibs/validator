#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-tiff-getexif-xresolution-tag-282
# @title: Pillow TIFF getexif exposes XResolution tag 282 with a float-castable rational
# @description: Saves a TIFF with dpi=(200, 200), reopens with Pillow, calls im.getexif() to obtain an Exif object, asserts 282 (XResolution) is a key in the mapping with a value castable to float equal to 200.0, asserts 283 (YResolution) is also present and equals 200.0, and asserts 296 (ResolutionUnit) is in the mapping with integer value 2 (inches), confirming libtiff IFD0 resolution tags surface via getexif.
# @timeout: 60
# @tags: usage, tiff, python, getexif, xresolution, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/exif.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (4, 4)).save(sys.argv[1], 'TIFF', dpi=(200, 200))

with Image.open(sys.argv[1]) as im:
    im.load()
    exif = im.getexif()
    assert 282 in exif, ('282 missing', dict(exif))
    assert 283 in exif, ('283 missing', dict(exif))
    assert 296 in exif, ('296 missing', dict(exif))
    assert float(exif[282]) == 200.0, ('x', exif[282])
    assert float(exif[283]) == 200.0, ('y', exif[283])
    assert int(exif[296]) == 2, ('unit', exif[296])
print('ok getexif x=%g y=%g unit=%d' % (float(exif[282]), float(exif[283]), int(exif[296])))
PY
