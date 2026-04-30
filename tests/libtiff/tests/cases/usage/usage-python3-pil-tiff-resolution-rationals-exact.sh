#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-resolution-rationals-exact
# @title: Pillow TIFF resolution exact rationals
# @description: Saves a TIFF with dpi=(72,144) and verifies tiffinfo reports XResolution/YResolution lines and PIL exposes the exact rational values via tag_v2.
# @timeout: 180
# @tags: usage, image, python, metadata, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/res.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image

size = (8, 6)
pixels = [
    ((x * 11) % 256, (y * 17) % 256, ((x + y) * 13) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1], dpi=(72, 144))
PY

validator_require_file "$img"

report="$tmpdir/info.txt"
tiffinfo "$img" >"$report"
validator_assert_contains "$report" "Resolution: 72, 144"

python3 - <<'PY' "$img"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    x_raw = im.tag_v2[282]
    y_raw = im.tag_v2[283]
    # Pillow returns a fractions.Fraction (or IFDRational) - exact rational.
    assert float(x_raw) == 72.0, x_raw
    assert float(y_raw) == 144.0, y_raw
    unit = im.tag_v2.get(296)
    assert unit == 2, unit
    print("res", float(x_raw), float(y_raw), unit)
PY
