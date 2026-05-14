#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-tiff-samples-per-pixel-rgb-equals-three
# @title: Pillow RGB TIFF reports SamplesPerPixel tag 277 equal to 3
# @description: Saves a small RGB TIFF with Pillow, reopens it, asserts tag_v2[277] (SamplesPerPixel) equals integer 3 and that the image mode is "RGB", confirming libtiff records three samples per pixel for the RGB photometric interpretation.
# @timeout: 60
# @tags: usage, tiff, python, samples, r17
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/spp.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (4, 4), (5, 6, 7)).save(sys.argv[1], 'TIFF', compression='raw')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'RGB', ('mode', im.mode)
    spp = im.tag_v2.get(277)
    assert spp == 3, ('SamplesPerPixel', spp)
print('ok spp=3')
PY
