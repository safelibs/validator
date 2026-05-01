#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-exact-transparent
# @title: Pillow WebP exact=True preserves transparent RGB
# @description: Saves an RGBA image with fully-transparent pixels carrying distinct RGB values to a lossless WebP using Pillow with exact=True, then reopens and asserts the transparent pixel's RGB values are preserved byte-for-byte.
# @timeout: 180
# @tags: usage, webp, python, alpha, lossless
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-exact-transparent"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmp = Path(sys.argv[2])

src = Image.new('RGBA', (4, 4), (0, 0, 0, 0))
# A few transparent pixels carry meaningful RGB that must survive when exact=True.
src.putpixel((0, 0), (200, 100, 50, 0))
src.putpixel((1, 1), (10, 220, 30, 0))
src.putpixel((2, 2), (40, 60, 240, 255))
src.putpixel((3, 3), (123, 45, 67, 128))

out = tmp / 'exact.webp'
src.save(out, 'WEBP', lossless=True, exact=True, quality=100)

with Image.open(out) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.mode in ('RGBA',), im.mode
    px00 = im.getpixel((0, 0))
    px11 = im.getpixel((1, 1))
    px22 = im.getpixel((2, 2))
    px33 = im.getpixel((3, 3))

assert px00 == (200, 100, 50, 0), px00
assert px11 == (10, 220, 30, 0), px11
assert px22 == (40, 60, 240, 255), px22
assert px33 == (123, 45, 67, 128), px33
print('exact-transparent', px00, px11, px22, px33)
PY
