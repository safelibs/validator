#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-tiff-getexif-returns-exif-mapping
# @title: Pillow getexif() on a TIFF returns an Exif mapping that contains the Software tag
# @description: Writes a TIFF with the Software tag (305) populated via tiffinfo, reopens it with Pillow, calls im.getexif() and asserts the returned object is an instance of PIL.Image.Exif whose mapping contains tag 305 equal to the original string, confirming libtiff EXIF-compatible tag exposure through Pillow's Exif API.
# @timeout: 60
# @tags: usage, tiff, python, exif, getexif, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/exif.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

ifd = ImageFileDirectory_v2()
ifd[305] = 'r18-pil-exif-software'
Image.new('RGB', (4, 4)).save(sys.argv[1], 'TIFF', tiffinfo=ifd)

with Image.open(sys.argv[1]) as im:
    exif = im.getexif()
    assert isinstance(exif, Image.Exif), type(exif)
    val = exif.get(305)
    assert val == 'r18-pil-exif-software', ('software', val)
print('ok exif software=%s' % val)
PY
