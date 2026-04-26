#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageFilter, ImageOps
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.webp'
Image.new('RGB', (4, 3), (120, 40, 200)).save(source, 'WEBP')

if case_id == 'usage-python3-pil-autocontrast-webp':
    with Image.open(source) as im:
        out = ImageOps.autocontrast(im)
        out.save(tmpdir / 'out.webp', 'WEBP')
    with Image.open(tmpdir / 'out.webp') as im:
        assert im.size == (4, 3)
        print('autocontrast', im.size)
elif case_id == 'usage-python3-pil-filter-blur-webp':
    with Image.open(source) as im:
        out = im.filter(ImageFilter.BLUR)
        out.save(tmpdir / 'out.webp', 'WEBP')
    with Image.open(tmpdir / 'out.webp') as im:
        assert im.size == (4, 3)
        print('blur', im.size)
elif case_id == 'usage-python3-pil-border-expand-webp':
    with Image.open(source) as im:
        out = ImageOps.expand(im, border=1, fill='black')
        out.save(tmpdir / 'out.webp', 'WEBP')
    with Image.open(tmpdir / 'out.webp') as im:
        assert im.size == (6, 5)
        print('expand', im.size)
elif case_id == 'usage-python3-pil-split-merge-webp':
    with Image.open(source) as im:
        out = Image.merge('RGB', im.split())
        out.save(tmpdir / 'out.webp', 'WEBP')
    with Image.open(tmpdir / 'out.webp') as im:
        assert im.mode == 'RGB'
        print('merge', im.mode)
elif case_id == 'usage-python3-pil-l-mode-webp':
    out = Image.new('L', (4, 3), 83)
    out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
    with Image.open(tmpdir / 'out.webp') as im:
        pixel = im.getpixel((0, 0))
        assert im.size == (4, 3)
        if isinstance(pixel, tuple):
            assert len(set(pixel[:3])) == 1
        print('l-mode', im.mode)
elif case_id == 'usage-python3-pil-solarize-webp':
    with Image.open(source) as im:
        out = ImageOps.solarize(im, threshold=128)
        out.save(tmpdir / 'out.webp', 'WEBP')
    with Image.open(tmpdir / 'out.webp') as im:
        assert im.size == (4, 3)
        print('solarize', im.size)
elif case_id == 'usage-python3-pil-posterize-webp':
    with Image.open(source) as im:
        out = ImageOps.posterize(im, bits=4)
        out.save(tmpdir / 'out.webp', 'WEBP')
    with Image.open(tmpdir / 'out.webp') as im:
        assert im.size == (4, 3)
        print('posterize', im.size)
elif case_id == 'usage-python3-pil-transpose-webp':
    with Image.open(source) as im:
        out = im.transpose(Image.Transpose.TRANSPOSE)
        out.save(tmpdir / 'out.webp', 'WEBP')
    with Image.open(tmpdir / 'out.webp') as im:
        assert im.size == (3, 4)
        print('transpose', im.size)
elif case_id == 'usage-python3-pil-canvas-paste-webp':
    with Image.open(source) as im:
        canvas = Image.new('RGB', (8, 6), 'white')
        canvas.paste(im, (2, 1))
        canvas.save(tmpdir / 'out.webp', 'WEBP')
    with Image.open(tmpdir / 'out.webp') as im:
        assert im.size == (8, 6)
        print('canvas', im.size)
elif case_id == 'usage-python3-pil-histogram-webp':
    with Image.open(source) as im:
        hist = im.histogram()
        assert len(hist) == 768
        print('histogram', len(hist))
else:
    raise SystemExit(f'unknown libwebp even-more usage case: {case_id}')
PY
