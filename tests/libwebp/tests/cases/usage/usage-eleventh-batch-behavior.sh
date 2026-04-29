#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from io import BytesIO
from PIL import Image, ImageSequence, ImageOps, features
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
base = Image.new('RGB', (5, 4), (20, 80, 160))

def reopen(path):
    im = Image.open(path)
    im.load()
    return im

if case_id == 'usage-python3-pil-webp-animated-frame-count-batch11':
    out = tmpdir / 'anim.webp'
    frames = [Image.new('RGB', (3, 2), color) for color in ((255, 0, 0), (0, 255, 0))]
    frames[0].save(out, 'WEBP', save_all=True, append_images=frames[1:], duration=50, loop=0, lossless=True)
    im = Image.open(out)
    assert getattr(im, 'is_animated', False)
    assert im.n_frames == 2
    print(im.n_frames)
elif case_id == 'usage-python3-pil-webp-animated-seek-second-batch11':
    out = tmpdir / 'anim.webp'
    frames = [Image.new('RGB', (2, 2), color) for color in ((10, 20, 30), (40, 50, 60))]
    frames[0].save(out, 'WEBP', save_all=True, append_images=frames[1:], duration=50, loop=0, lossless=True)
    im = Image.open(out)
    im.seek(1)
    assert im.getpixel((0, 0)) == (40, 50, 60)
    print(im.tell())
elif case_id == 'usage-python3-pil-webp-rgba-alpha-extrema-batch11':
    out = tmpdir / 'alpha.webp'
    rgba = Image.new('RGBA', (2, 1))
    rgba.putdata([(1, 2, 3, 0), (4, 5, 6, 255)])
    rgba.save(out, 'WEBP', lossless=True)
    im = reopen(out).convert('RGBA')
    assert im.getchannel('A').getextrema() == (0, 255)
    print(im.getchannel('A').getextrema())
elif case_id == 'usage-python3-pil-webp-lossless-rgb-mode-batch11':
    out = tmpdir / 'rgb.webp'
    base.save(out, 'WEBP', lossless=True)
    im = reopen(out)
    assert im.mode == 'RGB' and im.size == base.size
    print(im.mode)
elif case_id == 'usage-python3-pil-webp-method-six-save-batch11':
    out = tmpdir / 'method.webp'
    base.save(out, 'WEBP', quality=80, method=6)
    im = reopen(out)
    assert im.format == 'WEBP'
    print(out.stat().st_size)
elif case_id == 'usage-python3-pil-webp-bytesio-open-batch11':
    buf = BytesIO()
    base.save(buf, 'WEBP', lossless=True)
    buf.seek(0)
    im = Image.open(buf)
    im.load()
    assert im.format == 'WEBP' and im.size == base.size
    print(im.format)
elif case_id == 'usage-python3-pil-webp-contain-size-batch11':
    out = tmpdir / 'contain.webp'
    contained = ImageOps.contain(base, (3, 3))
    contained.save(out, 'WEBP', lossless=True)
    im = reopen(out)
    assert im.size[0] <= 3 and im.size[1] <= 3
    print(im.size)
elif case_id == 'usage-python3-pil-webp-feature-check-batch11':
    assert features.check('webp')
    print('webp')
elif case_id == 'usage-python3-pil-webp-exif-empty-roundtrip-batch11':
    out = tmpdir / 'exif.webp'
    exif = Image.Exif()
    exif[274] = 1
    base.save(out, 'WEBP', lossless=True, exif=exif)
    im = reopen(out)
    assert im.getexif().get(274) == 1
    print(im.getexif().get(274))
elif case_id == 'usage-python3-pil-webp-palette-convert-batch11':
    out = tmpdir / 'palette.webp'
    pal = base.convert('P', palette=Image.Palette.ADAPTIVE, colors=4).convert('RGB')
    pal.save(out, 'WEBP', lossless=True)
    im = reopen(out)
    assert im.mode == 'RGB' and im.size == base.size
    print(im.mode)
else:
    raise SystemExit(f'unknown libwebp eleventh-batch usage case: {case_id}')
PYCASE
