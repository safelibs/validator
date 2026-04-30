#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcrop-rotate-90
# @title: Pillow TIFF tiffcrop rotate 90
# @description: Writes a TIFF with Pillow then runs tiffcrop -R 90 and verifies the rotated dimensions and PIL mode on reload.
# @timeout: 180
# @tags: usage, image, python, transform
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src.tiff"
rot="$tmpdir/rot.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

size = (32, 20)
pixels = [
    ((x * 4) % 256, (y * 6) % 256, ((x + y) * 8) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$src"
tiffcrop -R 90 "$src" "$rot"
validator_require_file "$rot"

python3 - <<'PY' "$rot"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    # 90-degree clockwise rotate swaps width and height: (32,20) -> (20,32).
    assert im.size == (20, 32), im.size
    assert im.mode == "RGB", im.mode
    width = im.tag_v2.get(256)
    length = im.tag_v2.get(257)
    assert width == 20, width
    assert length == 32, length
    print("rotate90", im.size, width, length)
PY
