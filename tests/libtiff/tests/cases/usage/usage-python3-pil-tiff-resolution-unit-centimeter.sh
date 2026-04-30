#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-resolution-unit-centimeter
# @title: Pillow TIFF resolution unit centimeter
# @description: Saves a TIFF with explicit ResolutionUnit=3 (centimeter) via tiffinfo and verifies the tag round-trips.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/cm.tiff"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2


def as_float(value):
    if isinstance(value, tuple):
        if len(value) == 2:
            return value[0] / value[1]
        if len(value) == 1:
            return as_float(value[0])
    return float(value)


path = sys.argv[1]
image = Image.new("RGB", (8, 6), (10, 20, 30))
ifd = ImageFileDirectory_v2()
ifd[282] = 100.0
ifd[283] = 100.0
ifd[296] = 3
image.save(path, tiffinfo=ifd)

with Image.open(path) as reopened:
    reopened.load()
    unit = reopened.tag_v2.get(296)
    x_res = as_float(reopened.tag_v2[282])
    y_res = as_float(reopened.tag_v2[283])
    assert unit == 3, unit
    assert x_res == 100.0, x_res
    assert y_res == 100.0, y_res
    assert reopened.size == (8, 6), reopened.size
    print("centimeter", unit, x_res, y_res)
PY
