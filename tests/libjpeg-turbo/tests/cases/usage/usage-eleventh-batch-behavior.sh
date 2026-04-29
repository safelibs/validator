#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageOps
from io import BytesIO
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
base = Image.new('RGB', (8, 6))
base.putdata([(x * 30 % 256, y * 40 % 256, (x + y) * 20 % 256) for y in range(6) for x in range(8)])
source = tmpdir / 'input.jpg'
base.save(source, 'JPEG', quality=95, subsampling=0)

def reopen(path):
    im = Image.open(path)
    im.load()
    return im

if case_id == 'usage-python3-pil-jpeg-dpi-roundtrip-batch11':
    out = tmpdir / 'dpi.jpg'
    base.save(out, 'JPEG', dpi=(72, 72), quality=90)
    im = reopen(out)
    assert tuple(round(v) for v in im.info.get('dpi', (0, 0))) == (72, 72)
    print(im.info.get('dpi'))
elif case_id == 'usage-python3-pil-jpeg-progressive-info-batch11':
    out = tmpdir / 'progressive.jpg'
    base.save(out, 'JPEG', progressive=True, quality=90)
    im = reopen(out)
    assert im.info.get('progressive') or im.info.get('progression')
    print('progressive')
elif case_id == 'usage-python3-pil-jpeg-quantization-table-batch11':
    im = reopen(source)
    assert getattr(im, 'quantization', None)
    assert len(im.quantization) >= 2
    print(len(im.quantization))
elif case_id == 'usage-python3-pil-jpeg-cmyk-roundtrip-batch11':
    out = tmpdir / 'cmyk.jpg'
    cmyk = Image.new('CMYK', (3, 2), (10, 20, 30, 40))
    cmyk.save(out, 'JPEG')
    im = reopen(out)
    assert im.mode == 'CMYK'
    assert im.size == (3, 2)
    print(im.mode)
elif case_id == 'usage-python3-pil-jpeg-exif-orientation-batch11':
    out = tmpdir / 'exif.jpg'
    exif = Image.Exif()
    exif[274] = 6
    base.save(out, 'JPEG', exif=exif)
    im = reopen(out)
    assert im.getexif().get(274) == 6
    print(im.getexif().get(274))
elif case_id == 'usage-python3-pil-jpeg-l-mode-roundtrip-batch11':
    out = tmpdir / 'gray.jpg'
    gray = base.convert('L')
    gray.save(out, 'JPEG')
    im = reopen(out)
    assert im.mode == 'L'
    assert im.size == base.size
    print(im.mode)
elif case_id == 'usage-python3-pil-jpeg-bytesio-open-batch11':
    buf = BytesIO()
    base.save(buf, 'JPEG', quality=90)
    buf.seek(0)
    im = Image.open(buf)
    im.load()
    assert im.format == 'JPEG'
    assert im.size == base.size
    print(im.format)
elif case_id == 'usage-python3-pil-jpeg-draft-load-batch11':
    im = Image.open(source)
    im.draft('RGB', (4, 3))
    im.load()
    assert im.size[0] <= 8 and im.size[1] <= 6
    print(im.size)
elif case_id == 'usage-python3-pil-jpeg-getbands-batch11':
    im = reopen(source)
    assert im.getbands() == ('R', 'G', 'B')
    print(','.join(im.getbands()))
elif case_id == 'usage-python3-pil-jpeg-optimize-save-batch11':
    out = tmpdir / 'opt.jpg'
    ImageOps.autocontrast(base).save(out, 'JPEG', optimize=True, quality=85)
    im = reopen(out)
    assert im.format == 'JPEG'
    assert im.size == base.size
    print(out.stat().st_size)
else:
    raise SystemExit(f'unknown libjpeg-turbo eleventh-batch usage case: {case_id}')
PYCASE
