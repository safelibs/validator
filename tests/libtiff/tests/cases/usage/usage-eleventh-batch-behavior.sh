#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageOps, ImageSequence
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
base = Image.new('RGB', (5, 4), (20, 40, 80))
source = tmpdir / 'input.tiff'
base.save(source, 'TIFF')

def reopen(path):
    im = Image.open(path)
    im.load()
    return im

if case_id == 'usage-python3-pil-tiff-description-tag-batch11':
    out = tmpdir / 'desc.tiff'
    base.save(out, 'TIFF', tiffinfo={270: 'validator description'})
    im = reopen(out)
    assert im.tag_v2.get(270) == 'validator description'
    print(im.tag_v2.get(270))
elif case_id == 'usage-python3-pil-tiff-dpi-info-batch11':
    out = tmpdir / 'dpi.tiff'
    base.save(out, 'TIFF', dpi=(300, 300))
    im = reopen(out)
    assert tuple(round(v) for v in im.info.get('dpi', (0, 0))) == (300, 300)
    print(im.info.get('dpi'))
elif case_id == 'usage-python3-pil-tiff-16bit-pixel-batch11':
    out = tmpdir / 'sixteen.tiff'
    img = Image.new('I;16', (2, 1))
    img.putdata([1, 1024])
    img.save(out, 'TIFF')
    im = reopen(out)
    assert im.getpixel((1, 0)) == 1024
    print(im.mode, im.getpixel((1, 0)))
elif case_id == 'usage-python3-pil-tiff-multipage-seek-third-batch11':
    out = tmpdir / 'multi.tiff'
    frames = [Image.new('L', (2, 2), value) for value in (10, 20, 30)]
    frames[0].save(out, save_all=True, append_images=frames[1:])
    im = Image.open(out)
    im.seek(2)
    assert im.getpixel((0, 0)) == 30
    print(im.n_frames)
elif case_id == 'usage-python3-pil-tiff-tobytes-length-batch11':
    im = reopen(source)
    data = im.tobytes()
    assert len(data) == im.size[0] * im.size[1] * 3
    print(len(data))
elif case_id == 'usage-python3-pil-tiff-getbands-batch11':
    im = reopen(source)
    assert im.getbands() == ('R', 'G', 'B')
    print(','.join(im.getbands()))
elif case_id == 'usage-python3-pil-tiff-expand-border-batch11':
    out = tmpdir / 'border.tiff'
    expanded = ImageOps.expand(base, border=2, fill=(1, 2, 3))
    expanded.save(out, 'TIFF')
    im = reopen(out)
    assert im.size == (9, 8)
    assert im.getpixel((0, 0)) == (1, 2, 3)
    print(im.size)
elif case_id == 'usage-python3-pil-tiff-invert-l-mode-batch11':
    out = tmpdir / 'invert.tiff'
    gray = Image.new('L', (2, 1))
    gray.putdata([0, 200])
    ImageOps.invert(gray).save(out, 'TIFF')
    im = reopen(out)
    assert list(im.getdata()) == [255, 55]
    print(list(im.getdata()))
elif case_id == 'usage-python3-pil-tiff-sequence-sum-batch11':
    out = tmpdir / 'seq.tiff'
    frames = [Image.new('L', (1, 1), value) for value in (4, 5, 6)]
    frames[0].save(out, save_all=True, append_images=frames[1:])
    im = Image.open(out)
    total = sum(frame.copy().getpixel((0, 0)) for frame in ImageSequence.Iterator(im))
    assert total == 15
    print(total)
elif case_id == 'usage-python3-pil-tiff-bytesio-open-batch11':
    from io import BytesIO
    buf = BytesIO()
    base.save(buf, 'TIFF')
    buf.seek(0)
    im = Image.open(buf)
    im.load()
    assert im.format == 'TIFF' and im.size == base.size
    print(im.format)
else:
    raise SystemExit(f'unknown libtiff eleventh-batch usage case: {case_id}')
PYCASE
