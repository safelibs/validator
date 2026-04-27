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
source = tmpdir / 'input.jpg'
base = Image.new('RGB', (4, 3))
base.putdata([
    (10, 20, 30), (40, 50, 60), (70, 80, 90), (100, 110, 120),
    (130, 30, 20), (20, 140, 40), (30, 50, 150), (200, 210, 40),
    (15, 200, 100), (220, 30, 180), (90, 160, 10), (250, 250, 250),
])
base.save(source, 'JPEG', quality=100, subsampling=0)
resampling = getattr(Image, 'Resampling', Image)

with Image.open(source) as opened:
    if case_id == 'usage-python3-pil-flip-left-right-jpeg':
        out = ImageOps.mirror(opened)
        assert out.getpixel((0, 0)) == opened.getpixel((3, 0))
        out.save(tmpdir / 'out.jpg', 'JPEG')
        print(out.size)
    elif case_id == 'usage-python3-pil-flip-top-bottom-jpeg':
        out = ImageOps.flip(opened)
        assert out.getpixel((0, 0)) == opened.getpixel((0, 2))
        out.save(tmpdir / 'out.jpg', 'JPEG')
        print(out.size)
    elif case_id == 'usage-python3-pil-autocontrast-jpeg':
        out = ImageOps.autocontrast(opened)
        assert out.size == opened.size
        out.save(tmpdir / 'out.jpg', 'JPEG')
        print(out.size)
    elif case_id == 'usage-python3-pil-solarize-jpeg':
        out = ImageOps.solarize(opened, threshold=100)
        assert out.getpixel((0, 0)) == opened.getpixel((0, 0))
        out.save(tmpdir / 'out.jpg', 'JPEG')
        print(out.size)
    elif case_id == 'usage-python3-pil-posterize-jpeg':
        out = ImageOps.posterize(opened, bits=3)
        assert out.mode == 'RGB'
        out.save(tmpdir / 'out.jpg', 'JPEG')
        print(out.mode)
    elif case_id == 'usage-python3-pil-green-channel-jpeg':
        out = opened.getchannel('G')
        assert out.getpixel((1, 1)) == opened.getpixel((1, 1))[1]
        out.save(tmpdir / 'out.jpg', 'JPEG')
        print(out.mode)
    elif case_id == 'usage-python3-pil-getbbox-jpeg':
        bbox = opened.getbbox()
        assert bbox == (0, 0, 4, 3)
        print(bbox)
    elif case_id == 'usage-python3-pil-resize-bicubic-jpeg':
        out = opened.resize((8, 6), resampling.BICUBIC)
        assert out.size == (8, 6)
        out.save(tmpdir / 'out.jpg', 'JPEG')
        print(out.size)
    elif case_id == 'usage-python3-pil-histogram-length-jpeg':
        hist = opened.histogram()
        assert len(hist) == 768
        print(len(hist))
    elif case_id == 'usage-python3-pil-crop-center-jpeg':
        out = opened.crop((1, 1, 3, 3))
        assert out.size == (2, 2)
        out.save(tmpdir / 'out.jpg', 'JPEG')
        print(out.size)
    else:
        raise SystemExit(f'unknown libjpeg-turbo expanded usage case: {case_id}')
PYCASE
