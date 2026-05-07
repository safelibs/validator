#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-tiff-getexif-software-tag-305
# @title: PIL TIFF getexif() round-trips a Software ASCII (tag 305) through libtiff
# @description: Builds a Pillow Exif object with tag 305 = "ValidatorR15Software", saves an RGB TIFF using exif=ex, and verifies on reopen that getexif()[305] decodes to the same string after stripping any trailing NUL byte (or bytes->str), asserting libtiff carries the Software ASCII through Pillow's getexif() round-trip.
# @timeout: 60
# @tags: usage, tiff, python, exif, software
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/software.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
expected = 'ValidatorR15Software'
img = Image.new('RGB', (8, 8), (10, 20, 30))
ex = img.getexif()
ex[305] = expected
img.save(sys.argv[1], 'TIFF', exif=ex)

with Image.open(sys.argv[1]) as im:
    im.load()
    val = im.getexif().get(305)
    if isinstance(val, bytes):
        val = val.decode('ascii', errors='strict').rstrip('\x00')
    elif isinstance(val, str):
        val = val.rstrip('\x00')
    assert val == expected, ('Software', val)
PY
