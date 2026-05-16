#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-tiff-getexif-yresolution-tag-283
# @title: Pillow getexif on a saved TIFF exposes YResolution at tag id 283
# @description: Saves a 5x5 RGB TIFF with dpi=(72, 144), reopens it, calls im.getexif() and asserts tag 283 (YResolution) is present and its rational/numeric value equals 144.0, validating libtiff resolution-tag emission via Pillow's EXIF mapping.
# @timeout: 60
# @tags: usage, tiff, python, exif, yresolution, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/dpi.tif" <<'PY'
import sys
from PIL import Image

Image.new('RGB', (5, 5), (1, 2, 3)).save(sys.argv[1], 'TIFF', dpi=(72, 144))

with Image.open(sys.argv[1]) as im:
    exif = im.getexif()
    assert 283 in exif, sorted(exif.keys())
    v = exif[283]
    # Pillow returns this either as a float or as an IFDRational; both convert to 144.0.
    assert float(v) == 144.0, v
    print('ok yres=%s' % (v,))
PY
