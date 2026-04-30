#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-72dpi-preserved
# @title: Pillow TIFF 72 dpi preserved
# @description: Saves a TIFF with dpi=(72,72) and verifies that XResolution, YResolution, and the info dpi tuple round-trip correctly.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/dpi72.tiff"
from PIL import Image
import sys

def as_float(value):
    if isinstance(value, tuple):
        if len(value) == 2:
            return value[0] / value[1]
        if len(value) == 1:
            return as_float(value[0])
    return float(value)

path = sys.argv[1]
image = Image.new("RGB", (8, 6), (40, 80, 160))
image.save(path, dpi=(72, 72))

with Image.open(path) as reopened:
    reopened.load()
    x_resolution = as_float(reopened.tag_v2[282])
    y_resolution = as_float(reopened.tag_v2[283])
    info_dpi = reopened.info.get("dpi")
    assert x_resolution == 72.0, x_resolution
    assert y_resolution == 72.0, y_resolution
    assert info_dpi is not None, "missing dpi info"
    assert tuple(float(v) for v in info_dpi) == (72.0, 72.0), info_dpi
    print("dpi", x_resolution, y_resolution)
PY
