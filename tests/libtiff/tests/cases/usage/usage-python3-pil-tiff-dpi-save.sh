#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/dpi.tiff"
from PIL import Image
import sys

def as_float(value):
    if isinstance(value, tuple):
        if len(value) == 2:
            return value[0] / value[1]
        if len(value) == 1:
            return as_float(value[0])
    return float(value)

size = (4, 3)
pixels = [
    ((x * 19 + y * 13) % 256, (x * 23 + y * 5) % 256, (x * 3 + y * 41) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1], dpi=(300, 300))

with Image.open(sys.argv[1]) as reopened:
    x_resolution = as_float(reopened.tag_v2[282])
    y_resolution = as_float(reopened.tag_v2[283])
    assert x_resolution == 300, x_resolution
    assert y_resolution == 300, y_resolution
    print("dpi", x_resolution, y_resolution)
PY
