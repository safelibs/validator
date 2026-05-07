#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-webp-getbands-rgba-four
# @title: Pillow lossless RGBA WEBP reload reports getbands() == ('R', 'G', 'B', 'A')
# @description: Saves an RGBA Pillow image as lossless WEBP, reloads, and asserts im.mode == 'RGBA' and im.getbands() returns the canonical 4-tuple ('R', 'G', 'B', 'A'), exercising libwebp's alpha-channel preservation through Pillow.
# @timeout: 180
# @tags: usage, python3-pil, webp, alpha
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/rgba.webp"
import sys
from PIL import Image
img = Image.new('RGBA', (24, 18))
for y in range(18):
    for x in range(24):
        img.putpixel((x, y), ((x * 7) & 0xff, (y * 13) & 0xff, ((x + y) * 5) & 0xff, ((x * y) & 0xff)))
img.save(sys.argv[1], 'WEBP', lossless=True)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.mode == 'RGBA', im.mode
    assert im.getbands() == ('R', 'G', 'B', 'A'), im.getbands()
    assert im.size == (24, 18), im.size
PY
