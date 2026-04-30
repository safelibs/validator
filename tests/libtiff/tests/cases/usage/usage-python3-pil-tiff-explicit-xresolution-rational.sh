#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-explicit-xresolution-rational
# @title: Pillow TIFF explicit XResolution rational tag via tiffinfo dict
# @description: Saves a TIFF with XResolution (282) and YResolution (283) injected as IFDRational(150/1) and (300/1) through a low-level ImageFileDirectory_v2, then verifies tiffinfo prints the resolutions and Pillow exposes the exact rational values.
# @timeout: 180
# @tags: usage, image, python, metadata, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/xres.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2, IFDRational

path = sys.argv[1]
size = (8, 6)
pixels = [
    ((x * 11) % 256, (y * 17) % 256, ((x + y) * 13) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)

ifd = ImageFileDirectory_v2()
ifd[282] = IFDRational(150, 1)
ifd[283] = IFDRational(300, 1)
ifd[296] = 2  # ResolutionUnit = inch
image.save(path, tiffinfo=ifd)
PY

validator_require_file "$img"

report="$tmpdir/info.txt"
tiffinfo "$img" >"$report"
validator_assert_contains "$report" "Resolution: 150, 300"

python3 - <<'PY' "$img"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    x_raw = im.tag_v2[282]
    y_raw = im.tag_v2[283]
    assert float(x_raw) == 150.0, x_raw
    assert float(y_raw) == 300.0, y_raw
    # Rational denominators preserved as 1.
    assert x_raw.denominator == 1, x_raw.denominator
    assert y_raw.denominator == 1, y_raw.denominator
    unit = im.tag_v2.get(296)
    assert unit == 2, unit
    print("xres", float(x_raw), float(y_raw), unit)
PY
