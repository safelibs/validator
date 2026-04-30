#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-resolution-unit-inch
# @title: Pillow TIFF resolution unit inch
# @description: Saves a TIFF with dpi=(150,150) and verifies the ResolutionUnit tag (296) is 2 (inch) and XResolution/YResolution round-trip.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/inch.tiff"
import sys
from PIL import Image


def as_float(value):
    if isinstance(value, tuple):
        if len(value) == 2:
            return value[0] / value[1]
        if len(value) == 1:
            return as_float(value[0])
    return float(value)


path = sys.argv[1]
image = Image.new("RGB", (10, 6), (32, 64, 96))
image.save(path, dpi=(150, 150))

with open(path, "rb") as fh:
    head = fh.read(4)
assert head[:2] in (b"II", b"MM"), head

with Image.open(path) as reopened:
    reopened.load()
    unit = reopened.tag_v2.get(296)
    x_res = as_float(reopened.tag_v2[282])
    y_res = as_float(reopened.tag_v2[283])
    assert unit == 2, unit
    assert x_res == 150.0, x_res
    assert y_res == 150.0, y_res
    info_dpi = reopened.info.get("dpi")
    assert info_dpi is not None, "missing dpi info"
    assert tuple(float(v) for v in info_dpi) == (150.0, 150.0), info_dpi
    print("inch", unit, x_res, y_res)
PY
