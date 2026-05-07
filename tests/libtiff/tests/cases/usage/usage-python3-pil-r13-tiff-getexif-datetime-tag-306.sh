#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-tiff-getexif-datetime-tag-306
# @title: PIL TIFF getexif() round-trips a DateTime ASCII (tag 306) through libtiff
# @description: Builds a Pillow Exif object with tag 306 = "2026:05:06 12:00:00", saves an RGB TIFF using exif=exif, and verifies on reopen that getexif()[306] decodes to the same string (after stripping any trailing NUL or bytes->str), asserting libtiff carries the EXIF DateTime ASCII through the Pillow round-trip.
# @timeout: 60
# @tags: usage, tiff, python, exif, datetime
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/exif.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
expected = '2026:05:06 12:00:00'
img = Image.new('RGB', (8, 8), (10, 20, 30))
ex = img.getexif()
ex[306] = expected
img.save(sys.argv[1], 'TIFF', exif=ex)

with Image.open(sys.argv[1]) as im:
    im.load()
    val = im.getexif().get(306)
    if isinstance(val, bytes):
        val = val.decode('ascii', errors='strict').rstrip('\x00')
    elif isinstance(val, str):
        val = val.rstrip('\x00')
    assert val == expected, ('DateTime', val)
PY
