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
source = tmpdir / 'input.jpg'
Image.new('RGB', (4, 3), (120, 40, 200)).save(source, 'JPEG')

if case_id == 'usage-python3-pil-autocontrast-jpeg':
    with Image.open(source) as im:
        out = ImageOps.autocontrast(im)
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as im:
        assert im.size == (4, 3)
        print('autocontrast', im.size)
elif case_id == 'usage-python3-pil-filter-blur-jpeg':
    with Image.open(source) as im:
        out = im.filter(ImageFilter.BLUR)
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as im:
        assert im.size == (4, 3)
        print('blur', im.size)
elif case_id == 'usage-python3-pil-border-expand-jpeg':
    with Image.open(source) as im:
        out = ImageOps.expand(im, border=1, fill='black')
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as im:
        assert im.size == (6, 5)
        print('expand', im.size)
elif case_id == 'usage-python3-pil-split-merge-jpeg':
    with Image.open(source) as im:
        out = Image.merge('RGB', im.split())
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as im:
        assert im.mode == 'RGB'
        print('merge', im.mode)
elif case_id == 'usage-python3-pil-l-mode-jpeg':
    with Image.open(source) as im:
        out = im.convert('L')
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as im:
        assert im.mode == 'L'
        print('l-mode', im.mode)
elif case_id == 'usage-python3-pil-solarize-jpeg':
    with Image.open(source) as im:
        out = ImageOps.solarize(im, threshold=128)
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as im:
        assert im.size == (4, 3)
        print('solarize', im.size)
elif case_id == 'usage-python3-pil-posterize-jpeg':
    with Image.open(source) as im:
        out = ImageOps.posterize(im, bits=4)
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as im:
        assert im.size == (4, 3)
        print('posterize', im.size)
elif case_id == 'usage-python3-pil-transpose-swap-jpeg':
    with Image.open(source) as im:
        out = im.transpose(Image.Transpose.TRANSPOSE)
        out.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as im:
        assert im.size == (3, 4)
        print('transpose', im.size)
elif case_id == 'usage-python3-pil-canvas-paste-jpeg':
    with Image.open(source) as im:
        canvas = Image.new('RGB', (8, 6), 'white')
        canvas.paste(im, (2, 1))
        canvas.save(tmpdir / 'out.jpg', 'JPEG')
    with Image.open(tmpdir / 'out.jpg') as im:
        assert im.size == (8, 6)
        print('canvas', im.size)
elif case_id == 'usage-python3-pil-histogram-jpeg':
    with Image.open(source) as im:
        hist = im.histogram()
        assert len(hist) == 768
        print('histogram', len(hist))
else:
    raise SystemExit(f'unknown libjpeg-turbo even-more usage case: {case_id}')
PY
