#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageChops, ImageOps, ImageSequence, ImageStat
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.tiff'
base = Image.new('RGB', (4, 3))
base.putdata([
    (10, 20, 30), (40, 50, 60), (70, 80, 90), (100, 110, 120),
    (130, 30, 20), (20, 140, 40), (30, 50, 150), (200, 210, 40),
    (15, 200, 100), (220, 30, 180), (90, 160, 10), (250, 250, 250),
])
base.save(source, 'TIFF')

if case_id == 'usage-python3-pil-equalize-tiff':
    with Image.open(source) as im:
        out = ImageOps.equalize(im)
        out.save(tmpdir / 'out.tiff', 'TIFF')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size == (4, 3)
        print('equalize', im.size)
elif case_id == 'usage-python3-pil-fit-tiff':
    with Image.open(source) as im:
        out = ImageOps.fit(im, (2, 2))
        out.save(tmpdir / 'out.tiff', 'TIFF')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size == (2, 2)
        print('fit', im.size)
elif case_id == 'usage-python3-pil-pad-tiff':
    with Image.open(source) as im:
        out = ImageOps.pad(im, (6, 6), color='white')
        out.save(tmpdir / 'out.tiff', 'TIFF')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size == (6, 6)
        print('pad', im.size)
elif case_id == 'usage-python3-pil-offset-tiff':
    with Image.open(source) as im:
        out = ImageChops.offset(im, 1, 1)
        out.save(tmpdir / 'out.tiff', 'TIFF')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size == (4, 3)
        print('offset', im.size)
elif case_id == 'usage-python3-pil-getextrema-tiff':
    with Image.open(source) as im:
        extrema = im.getextrema()
        assert len(extrema) == 3
        print('extrema', extrema[0][0], extrema[2][1])
elif case_id == 'usage-python3-pil-red-channel-tiff':
    with Image.open(source) as im:
        out = im.getchannel('R')
        out.save(tmpdir / 'out.tiff', 'TIFF')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.mode == 'L'
        print('channel', im.mode)
elif case_id == 'usage-python3-pil-rotate-expand-tiff':
    with Image.open(source) as im:
        out = im.rotate(45, expand=True)
        out.save(tmpdir / 'out.tiff', 'TIFF')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.size[0] > 4 and im.size[1] > 3
        print('rotate-expand', im.size)
elif case_id == 'usage-python3-pil-quantize-tiff':
    with Image.open(source) as im:
        out = im.quantize(colors=8)
        out.save(tmpdir / 'out.tiff', 'TIFF')
    with Image.open(tmpdir / 'out.tiff') as im:
        assert im.mode == 'P'
        print('quantize', im.mode)
elif case_id == 'usage-python3-pil-stat-mean-tiff':
    with Image.open(source) as im:
        mean = ImageStat.Stat(im).mean
        assert len(mean) == 3
        print('mean', round(mean[1], 2))
elif case_id == 'usage-python3-pil-sequence-iterator-tiff':
    first = Image.new('RGB', (2, 2), 'red')
    second = Image.new('RGB', (2, 2), 'blue')
    first.save(tmpdir / 'multi.tiff', save_all=True, append_images=[second])
    with Image.open(tmpdir / 'multi.tiff') as im:
        frames = list(ImageSequence.Iterator(im))
        assert len(frames) == 2
        print('frames', len(frames))
else:
    raise SystemExit(f'unknown libtiff further usage case: {case_id}')
PYCASE
