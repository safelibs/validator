#!/usr/bin/env bash
# @testcase: usage-python3-pil-quantize-jpeg
# @title: python PIL quantize JPEG
# @description: Exercises python pil quantize jpeg through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-quantize-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageChops, ImageOps, ImageStat
import random
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.jpg'
base = Image.new('RGB', (4, 3))
base.putdata([
    (10, 20, 30), (40, 50, 60), (70, 80, 90), (100, 110, 120),
    (130, 30, 20), (20, 140, 40), (30, 50, 150), (200, 210, 40),
    (15, 200, 100), (220, 30, 180), (90, 160, 10), (250, 250, 250),
])
base.save(source, 'JPEG', quality=100, subsampling=0)
resampling = getattr(Image, 'Resampling', Image)

def rgb_pixels(image):
    return list(image.convert('RGB').getdata())

def channel_extrema(image):
    pixels = rgb_pixels(image)
    return tuple((min(pixel[index] for pixel in pixels), max(pixel[index] for pixel in pixels)) for index in range(3))

with Image.open(source) as im:
    out = im.quantize(colors=8)
    assert out.mode == 'P'
    assert len(im.convert('RGB').getcolors(maxcolors=256)) > 8
    assert len(out.getcolors(maxcolors=256)) <= 8
    out.convert('RGB').save(tmpdir / 'out.jpg', 'JPEG')
with Image.open(tmpdir / 'out.jpg') as reopened:
    assert reopened.mode == 'RGB'
    print('quantize', reopened.mode)
PYCASE
