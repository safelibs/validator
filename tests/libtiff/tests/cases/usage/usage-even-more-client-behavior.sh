#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from pathlib import Path
from PIL import Image, ImageFilter, ImageOps
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

if case_id == 'usage-python3-pil-autocontrast-tiff':
    with Image.open(fixture) as im:
        out = ImageOps.autocontrast(im)
        out.save(tmpdir / 'out.tiff')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size[0] > 0 and im.size[1] > 0
        print('autocontrast', im.size)
elif case_id == 'usage-python3-pil-filter-detail-tiff':
    with Image.open(fixture) as im:
        out = im.filter(ImageFilter.DETAIL)
        out.save(tmpdir / 'out.tiff')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size[0] > 0 and im.size[1] > 0
        print('detail', im.size)
elif case_id == 'usage-python3-pil-border-expand-tiff':
    with Image.open(fixture) as im:
        original_size = im.size
        out = ImageOps.expand(im, border=1, fill='black')
        out.save(tmpdir / 'out.tiff')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size == (original_size[0] + 2, original_size[1] + 2)
        print('expand', im.size)
elif case_id == 'usage-python3-pil-split-merge-bands-tiff':
    with Image.open(fixture) as im:
        out = Image.merge(im.mode, im.split())
        out.save(tmpdir / 'out.tiff')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.mode == 'RGB'
        print('merge', im.mode)
elif case_id == 'usage-python3-pil-l-mode-tiff':
    with Image.open(fixture) as im:
        out = im.convert('L')
        out.save(tmpdir / 'out.tiff')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.mode == 'L'
        print('l', im.mode)
elif case_id == 'usage-python3-pil-invert-point-tiff':
    with Image.open(fixture) as im:
        out = im.point(lambda value: 255 - value)
        out.save(tmpdir / 'out.tiff')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size[0] > 0 and im.size[1] > 0
        print('invert', im.size)
elif case_id == 'usage-python3-pil-histogram-tiff':
    with Image.open(fixture) as im:
        hist = im.histogram()
        assert len(hist) == 768
        print('histogram', len(hist))
elif case_id == 'usage-python3-pil-rotate-180-tiff':
    with Image.open(fixture) as im:
        out = im.transpose(Image.Transpose.ROTATE_180)
        out.save(tmpdir / 'out.tiff')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size[0] > 0 and im.size[1] > 0
        print('rotate', im.size)
elif case_id == 'usage-python3-pil-canvas-paste-tiff':
    with Image.open(fixture) as im:
        canvas = Image.new('RGB', (8, 6), 'white')
        canvas.paste(im, (2, 1))
        canvas.save(tmpdir / 'out.tiff')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size == (8, 6)
        print('canvas', im.size)
elif case_id == 'usage-python3-pil-crop-generated-tiff':
    with Image.open(fixture) as im:
        out = im.crop((0, 0, 2, 2))
        out.save(tmpdir / 'out.tiff')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size == (2, 2)
        print('crop', im.size)
else:
    raise SystemExit(f'unknown libtiff even-more usage case: {case_id}')
PY
