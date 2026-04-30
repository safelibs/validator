#!/usr/bin/env bash
# @testcase: usage-python3-pil-histogram-rgb-length-jpeg
# @title: Pillow histogram length 768 for RGB JPEG
# @description: Loads an RGB JPEG and verifies Image.histogram() returns 768 entries (256 per channel) and that the totals sum to width*height per band.
# @timeout: 120
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-histogram-rgb-length-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.jpg'
Image.new('RGB', (16, 16), (128, 128, 128)).save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.mode == 'RGB'
    w, h = im.size
    hist = im.histogram()
    assert len(hist) == 768, len(hist)
    pixels = w * h
    for band in range(3):
        band_sum = sum(hist[band * 256:(band + 1) * 256])
        assert band_sum == pixels, (band, band_sum, pixels)
    print('histogram', len(hist), pixels)
PYCASE
