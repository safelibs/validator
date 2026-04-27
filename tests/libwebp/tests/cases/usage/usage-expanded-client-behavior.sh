#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageOps
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

with Image.open(source) as opened:
    if case_id == 'usage-python3-pil-flip-left-right-webp':
        out = ImageOps.mirror(opened)
        assert out.getpixel((0, 0)) == opened.getpixel((3, 0))
        out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
        print(out.size)
    elif case_id == 'usage-python3-pil-flip-top-bottom-webp':
        out = ImageOps.flip(opened)
        assert out.getpixel((0, 0)) == opened.getpixel((0, 2))
        out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
        print(out.size)
    elif case_id == 'usage-python3-pil-autocontrast-webp':
        out = ImageOps.autocontrast(opened)
        assert out.size == opened.size
        out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
        print(out.size)
    elif case_id == 'usage-python3-pil-solarize-webp':
        out = ImageOps.solarize(opened, threshold=100)
        out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
        print(out.size)
    elif case_id == 'usage-python3-pil-posterize-webp':
        out = ImageOps.posterize(opened, bits=3)
        assert out.mode == 'RGB'
        out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
        print(out.mode)
    elif case_id == 'usage-python3-pil-blue-channel-webp':
        out = opened.getchannel('B')
        expected = out.getpixel((2, 1))
        assert expected == opened.getpixel((2, 1))[2]
        out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
        print(expected)
    elif case_id == 'usage-python3-pil-getbbox-webp':
        bbox = opened.getbbox()
        assert bbox == (0, 0, 4, 3)
        print(bbox)
    elif case_id == 'usage-python3-pil-resize-bicubic-webp':
        out = opened.resize((8, 6), resampling.BICUBIC)
        assert out.size == (8, 6)
        out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
        print(out.size)
    elif case_id == 'usage-python3-pil-histogram-length-webp':
        hist = opened.histogram()
        assert len(hist) == 768
        print(len(hist))
    elif case_id == 'usage-python3-pil-crop-center-webp':
        out = opened.crop((1, 1, 3, 3))
        assert out.size == (2, 2)
        out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
        print(out.size)
    else:
        raise SystemExit(f'unknown libwebp expanded usage case: {case_id}')
PYCASE
