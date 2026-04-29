#!/usr/bin/env bash
# @testcase: usage-python3-pil-contain-webp
# @title: python PIL contain WebP
# @description: Exercises python pil contain webp through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-contain-webp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageChops, ImageOps, ImageStat
import random
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.webp'
base = Image.new('RGB', (4, 3))
base.putdata([
    (10, 20, 30), (40, 50, 60), (70, 80, 90), (100, 110, 120),
    (130, 30, 20), (20, 140, 40), (30, 50, 150), (200, 210, 40),
    (15, 200, 100), (220, 30, 180), (90, 160, 10), (250, 250, 250),
])
base.save(source, 'WEBP', lossless=True)
resampling = getattr(Image, 'Resampling', Image)

def rgb_pixels(image):
    return list(image.convert('RGB').getdata())

def channel_extrema(image):
    pixels = rgb_pixels(image)
    return tuple((min(pixel[index] for pixel in pixels), max(pixel[index] for pixel in pixels)) for index in range(3))

with Image.open(source) as im:
    out = ImageOps.contain(im, (3, 3), method=resampling.NEAREST)
    expected = im.resize((3, 2), resampling.NEAREST)
    assert rgb_pixels(out) == rgb_pixels(expected)
    out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
with Image.open(tmpdir / 'out.webp') as reopened:
    assert reopened.size == (3, 2)
    print('contain', reopened.size)
PYCASE
