#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-webp-exact-flag-rgba-roundtrip
# @title: Pillow WEBP exact=True preserves fully transparent RGBA pixels losslessly
# @description: Saves an RGBA image with fully transparent pixels carrying nonzero color via Pillow with lossless=True and exact=True, then reopens and asserts the alpha=0 pixels keep their original RGB values byte-for-byte.
# @timeout: 180
# @tags: usage, python3-pil, webp, alpha
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/exact.webp"
import sys
from PIL import Image

src = Image.new('RGBA', (8, 8))
for y in range(8):
    for x in range(8):
        # Fully transparent pixels with distinctive nonzero colour.
        src.putpixel((x, y), (200, 50, 90, 0))
# A single opaque pixel anchors the alpha mask.
src.putpixel((0, 0), (10, 10, 10, 255))

src.save(sys.argv[1], 'WEBP', lossless=True, exact=True)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    rgba = im.convert('RGBA')
    # Transparent pixel RGB must survive thanks to exact=True.
    assert rgba.getpixel((4, 4)) == (200, 50, 90, 0), rgba.getpixel((4, 4))
    assert rgba.getpixel((0, 0)) == (10, 10, 10, 255), rgba.getpixel((0, 0))
PY
