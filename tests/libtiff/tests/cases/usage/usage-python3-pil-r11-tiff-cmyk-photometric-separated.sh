#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-tiff-cmyk-photometric-separated
# @title: PIL CMYK TIFF reports separated photometric and SamplesPerPixel 4
# @description: Saves a Pillow CMYK image to TIFF and verifies tiffinfo reports "Photometric Interpretation: separated" and "Samples/Pixel: 4", reflecting the four ink channels of CMYK.
# @timeout: 60
# @tags: usage, tiff, python, cmyk, photometric
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/cmyk.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('CMYK', (40, 30), (50, 100, 150, 30)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.tag_v2.get(262) == 5, ('Photometric', im.tag_v2.get(262))
    assert im.tag_v2.get(277) == 4, ('SamplesPerPixel', im.tag_v2.get(277))
PY

tiffinfo "$path" >"$tmpdir/info.out"
grep -E 'Photometric Interpretation: separated' "$tmpdir/info.out" >/dev/null
grep -E 'Samples/Pixel: 4' "$tmpdir/info.out" >/dev/null
