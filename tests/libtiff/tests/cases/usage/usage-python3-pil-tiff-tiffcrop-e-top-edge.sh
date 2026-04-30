#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcrop-e-top-edge
# @title: Pillow TIFF tiffcrop -E t top-edge crop
# @description: Writes a 40x100 RGB TIFF with Pillow, runs tiffcrop -E t -m 0,0,80,0 -U px to crop 80 rows off the bottom (origin = top edge), and verifies the cropped output is 40x20 with matching ImageWidth/ImageLength tags via Pillow.
# @timeout: 180
# @tags: usage, image, python, cli, transform
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src.tiff"
cropped="$tmpdir/cropped.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

size = (40, 100)
pixels = [
    ((x * 4) % 256, (y * 5) % 256, ((x + y) * 7) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$src"

# -E t : origin at top edge.
# -m top,left,bottom,right margins in pixels (-U px).
# 0,0,80,0 removes the bottom 80 rows, leaving the top 20 rows of a 40x100.
tiffcrop -E t -m 0,0,80,0 -U px "$src" "$cropped"
validator_require_file "$cropped"

python3 - <<'PY' "$cropped"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.size == (40, 20), im.size
    assert im.mode == "RGB", im.mode
    width = im.tag_v2.get(256)
    length = im.tag_v2.get(257)
    assert width == 40, width
    assert length == 20, length
    # The first row of the crop must equal the first row of the source -
    # that is what "origin at top edge" means.
    top_left = im.getpixel((0, 0))
    assert top_left == (0, 0, 0), top_left
    print("crop-top", im.size, width, length)
PY
