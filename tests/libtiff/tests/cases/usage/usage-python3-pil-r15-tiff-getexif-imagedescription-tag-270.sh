#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-tiff-getexif-imagedescription-tag-270
# @title: PIL TIFF getexif() round-trips ImageDescription ASCII (tag 270) through libtiff
# @description: Builds a Pillow Exif object with tag 270 (ImageDescription) = "validator r15 description", saves an RGB TIFF using exif=ex, and verifies on reopen that getexif()[270] decodes to the same string after stripping trailing NUL bytes, asserting libtiff carries the ImageDescription ASCII through Pillow's getexif() round-trip.
# @timeout: 60
# @tags: usage, tiff, python, exif, image-description
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/imdesc.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
expected = 'validator r15 description'
img = Image.new('RGB', (8, 8), (90, 80, 70))
ex = img.getexif()
ex[270] = expected
img.save(sys.argv[1], 'TIFF', exif=ex)

with Image.open(sys.argv[1]) as im:
    im.load()
    val = im.getexif().get(270)
    if isinstance(val, bytes):
        val = val.decode('ascii', errors='strict').rstrip('\x00')
    elif isinstance(val, str):
        val = val.rstrip('\x00')
    assert val == expected, ('ImageDescription', val)
PY
