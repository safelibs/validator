#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-getexif-make-model-roundtrip
# @title: PIL TIFF getexif() round-trips Make (271) and Model (272) ASCII strings
# @description: Builds a Pillow Exif object with tag 271 (Make) = "ValidatorCo" and 272 (Model) = "ValidatorCam X1", saves an RGB TIFF using exif=exif, and verifies on reopen that getexif()[271] and getexif()[272] decode (after stripping any trailing NUL or bytes->str) to the same strings, asserting libtiff carries the Make/Model ASCII through the Pillow round-trip.
# @timeout: 60
# @tags: usage, tiff, python, exif, make, model
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/makemodel.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
make_expected = 'ValidatorCo'
model_expected = 'ValidatorCam X1'
img = Image.new('RGB', (16, 16), (12, 34, 56))
ex = img.getexif()
ex[271] = make_expected
ex[272] = model_expected
img.save(sys.argv[1], 'TIFF', exif=ex)

def _norm(v):
    if isinstance(v, bytes):
        v = v.decode('ascii', errors='strict')
    return v.rstrip('\x00') if isinstance(v, str) else v

with Image.open(sys.argv[1]) as im:
    im.load()
    got_make = _norm(im.getexif().get(271))
    got_model = _norm(im.getexif().get(272))
    assert got_make == make_expected, ('Make', got_make)
    assert got_model == model_expected, ('Model', got_model)
PY
