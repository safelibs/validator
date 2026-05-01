#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-alpha-quality
# @title: Pillow WebP save alpha_quality kwarg
# @description: Saves an RGBA image to WebP via Pillow with quality=80 and alpha_quality=40, then reopens the file and asserts it remains an RGBA WebP at the source dimensions with the alpha channel preserved.
# @timeout: 180
# @tags: usage, webp, python, alpha
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-alpha-quality"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmp = Path(sys.argv[2])

src = Image.new('RGBA', (16, 12))
for y in range(12):
    for x in range(16):
        src.putpixel((x, y), ((x * 17) % 256, (y * 23) % 256, ((x + y) * 13) % 256, (x * 16) % 256))

out = tmp / 'aq.webp'
src.save(out, 'WEBP', quality=80, alpha_quality=40)

assert out.is_file()
header = out.read_bytes()[:12]
assert header[:4] == b'RIFF', header[:4]
assert header[8:12] == b'WEBP', header[8:12]

with Image.open(out) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (16, 12), im.size
    rgba = im.convert('RGBA')
    bands = rgba.split()
    assert len(bands) == 4, len(bands)
    extrema = bands[3].getextrema()
    # alpha should still vary (lossy alpha_quality=40 is low but non-flat)
    assert extrema[0] != extrema[1], extrema
    print('alpha_quality alpha-extrema', extrema)
PY
