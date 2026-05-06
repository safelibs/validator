#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-tiff-bilevel-mode-photometric
# @title: PIL TIFF saved from mode "1" reports min-is-black photometric
# @description: Saves a Pillow mode='1' bilevel image to TIFF and verifies tiffinfo reports "Photometric Interpretation: min-is-black" (PhotometricInterpretation tag value 1) which is the libtiff convention for 1-bit bitmaps written from PIL.
# @timeout: 60
# @tags: usage, tiff, python, photometric, bilevel
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/bilevel.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('1', (16, 16), 0).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.tag_v2.get(262) == 1, ('Photometric', im.tag_v2.get(262))
PY

tiffinfo "$path" | grep -E 'Photometric Interpretation: min-is-black' >/dev/null
