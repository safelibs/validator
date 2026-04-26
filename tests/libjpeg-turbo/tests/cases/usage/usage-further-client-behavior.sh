#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

if case_id == 'usage-python3-pil-equalize-jpeg':
    equalize_source = tmpdir / 'equalize.jpg'
    contrast = Image.new('L', (1024, 1))
    rng = random.Random(0)
    contrast.putdata([40 + rng.randrange(41) for _ in range(1024)])
    contrast.save(equalize_source, 'JPEG', quality=100, subsampling=0)
    with Image.open(equalize_source) as im:
        work = im.convert('L')
        out = ImageOps.equalize(work)
        out.save(tmpdir / 'out.jpg', 'JPEG')
        assert ImageChops.difference(work, out).getbbox() is not None
        low, high = out.getextrema()
        assert low <= 5 and high >= 250, (low, high)
    with Image.open(tmpdir / 'out.jpg') as reopened:
        assert reopened.size == (1024, 1)
        print('equalize', reopened.size)
elif case_id == 'usage-python3-pil-fit-jpeg':
    with Image.open(source) as im:
        out = ImageOps.fit(im, (2, 2), method=resampling.NEAREST, centering=(0, 0))
        expected = im.crop((0, 0, 3, 3)).resize((2, 2), resampling.NEAREST)
        assert rgb_pixels(out) == rgb_pixels(expected)
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as reopened:
        assert reopened.size == (2, 2)
        print('fit', reopened.size)
elif case_id == 'usage-python3-pil-pad-jpeg':
    with Image.open(source) as im:
        out = ImageOps.pad(im, (6, 6), color='white', method=resampling.NEAREST)
        assert out.getpixel((0, 0)) == (255, 255, 255)
        assert out.getpixel((5, 5)) == (255, 255, 255)
        assert out.getpixel((3, 3)) != (255, 255, 255)
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as reopened:
        assert reopened.size == (6, 6)
        print('pad', reopened.size)
elif case_id == 'usage-python3-pil-offset-jpeg':
    with Image.open(source) as im:
        out = ImageChops.offset(im, 1, 1)
        assert out.getpixel((1, 1)) == im.getpixel((0, 0))
        assert out.getpixel((0, 0)) == im.getpixel((3, 2))
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as reopened:
        assert reopened.size == (4, 3)
        print('offset', reopened.size)
elif case_id == 'usage-python3-pil-getextrema-jpeg':
    with Image.open(source) as im:
        extrema = im.getextrema()
        assert extrema == channel_extrema(im)
        print('extrema', extrema[0][0], extrema[2][1])
elif case_id == 'usage-python3-pil-red-channel-jpeg':
    with Image.open(source) as im:
        out = im.getchannel('R')
        assert out.getpixel((2, 1)) == im.getpixel((2, 1))[0]
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as reopened:
        assert reopened.mode == 'L'
        assert reopened.size == (4, 3)
        print('channel', reopened.mode)
elif case_id == 'usage-python3-pil-rotate-expand-jpeg':
    with Image.open(source) as im:
        out = im.rotate(45, expand=True, fillcolor=(0, 0, 0), resample=resampling.NEAREST)
        assert out.size == (6, 5)
        assert out.getpixel((0, 0)) == (0, 0, 0)
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as reopened:
        assert reopened.size == (6, 5)
        print('rotate-expand', reopened.size)
elif case_id == 'usage-python3-pil-contain-jpeg':
    with Image.open(source) as im:
        out = ImageOps.contain(im, (3, 3), method=resampling.NEAREST)
        expected = im.resize((3, 2), resampling.NEAREST)
        assert rgb_pixels(out) == rgb_pixels(expected)
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as reopened:
        assert reopened.size == (3, 2)
        print('contain', reopened.size)
elif case_id == 'usage-python3-pil-quantize-jpeg':
    with Image.open(source) as im:
        out = im.quantize(colors=8)
        assert out.mode == 'P'
        assert len(im.convert('RGB').getcolors(maxcolors=256)) > 8
        assert len(out.getcolors(maxcolors=256)) <= 8
        out.convert('RGB').save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as reopened:
        assert reopened.mode == 'RGB'
        print('quantize', reopened.mode)
elif case_id == 'usage-python3-pil-stat-mean-jpeg':
    with Image.open(source) as im:
        mean = ImageStat.Stat(im).mean
        pixels = rgb_pixels(im)
        manual = [sum(pixel[index] for pixel in pixels) / len(pixels) for index in range(3)]
        assert all(abs(observed - expected) < 1e-9 for observed, expected in zip(mean, manual))
        print('mean', round(mean[0], 2))
else:
    raise SystemExit(f'unknown libjpeg-turbo further usage case: {case_id}')
PYCASE
