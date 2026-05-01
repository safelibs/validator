#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-getexif-datetime-roundtrip
# @title: Pillow TIFF getexif() exposes DateTime tag (306) saved via exif kwarg
# @description: Builds a Pillow Exif object, sets DateTime (306) to a known string, saves an RGB TIFF with exif=exif, reopens the file, and verifies that getexif() returns the DateTime back exactly and that the tag also appears in the top-level tag_v2 dictionary, confirming the EXIF round-trip path works through libtiff.
# @timeout: 180
# @tags: usage, image, python, exif, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/exif.tiff"
import sys
from PIL import Image

path = sys.argv[1]
size = (8, 6)
image = Image.new("RGB", size, (10, 20, 30))
exif = image.getexif()
expected = "2024:11:30 18:45:00"
exif[306] = expected
image.save(path, exif=exif)

with Image.open(path) as reopened:
    reopened.load()
    out = reopened.getexif()
    actual = out.get(306)
    if isinstance(actual, bytes):
        actual = actual.decode("ascii", errors="strict").rstrip("\x00")
    elif isinstance(actual, str):
        actual = actual.rstrip("\x00")
    assert actual == expected, ("DateTime", actual)
    # The tag should also be visible at the top-level tag_v2 of the TIFF IFD.
    tagged = reopened.tag_v2.get(306)
    if isinstance(tagged, bytes):
        tagged = tagged.decode("ascii", errors="strict")
    if isinstance(tagged, str):
        tagged = tagged.rstrip("\x00")
    assert tagged == expected, ("tag_v2 306", tagged)
    assert reopened.size == size, reopened.size
    assert reopened.mode == "RGB", reopened.mode
    print("exif-datetime", actual)
PY
