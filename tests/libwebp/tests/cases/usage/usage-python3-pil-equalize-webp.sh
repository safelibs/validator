#!/usr/bin/env bash
# @testcase: usage-python3-pil-equalize-webp
# @title: python PIL equalize WebP
# @description: Exercises python pil equalize webp through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-equalize-webp"
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

equalize_source = tmpdir / 'equalize.webp'
contrast = Image.new('L', (1024, 1))
rng = random.Random(0)
contrast.putdata([40 + rng.randrange(41) for _ in range(1024)])
contrast.save(equalize_source, 'WEBP', lossless=True)
with Image.open(equalize_source) as im:
    work = im.convert('L')
    out = ImageOps.equalize(work)
    out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
    assert ImageChops.difference(work, out).getbbox() is not None
    low, high = out.getextrema()
    assert low <= 5 and high >= 250, (low, high)
with Image.open(tmpdir / 'out.webp') as reopened:
    assert reopened.size == (1024, 1)
    print('equalize', reopened.size)
PYCASE
