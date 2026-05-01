#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-resolution-unit-none
# @title: Pillow TIFF ResolutionUnit (296) saved as 1 (no absolute unit)
# @description: Saves a TIFF with explicit ResolutionUnit=1 (no absolute unit, so the X/YResolution rationals describe an aspect ratio only) via tiffinfo and verifies the tag round-trips as 1 while the rationals XResolution (282) and YResolution (283) preserve their ratio after reload.
# @timeout: 180
# @tags: usage, image, python, metadata, resolution
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/none.tiff"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2


def first(value):
    if isinstance(value, tuple):
        return value[0]
    return value


def as_float(value):
    if isinstance(value, tuple):
        if len(value) == 2 and all(isinstance(v, int) for v in value):
            return value[0] / value[1]
        if len(value) == 1:
            return as_float(value[0])
    return float(value)


path = sys.argv[1]
ifd = ImageFileDirectory_v2()
ifd[282] = 2.0
ifd[283] = 1.0
ifd[296] = 1
image = Image.new("RGB", (8, 6), (200, 100, 50))
image.save(path, tiffinfo=ifd)

with Image.open(path) as reopened:
    reopened.load()
    unit = first(reopened.tag_v2.get(296))
    x = as_float(reopened.tag_v2[282])
    y = as_float(reopened.tag_v2[283])
    assert unit == 1, ("ResolutionUnit", reopened.tag_v2.get(296))
    assert abs(x - 2.0) < 1e-6, ("XResolution", x)
    assert abs(y - 1.0) < 1e-6, ("YResolution", y)
    # 2:1 aspect ratio preserved.
    assert abs((x / y) - 2.0) < 1e-6, ("aspect", x, y)
    assert reopened.size == (8, 6), reopened.size
    print("none-unit", unit, x, y)
PY
