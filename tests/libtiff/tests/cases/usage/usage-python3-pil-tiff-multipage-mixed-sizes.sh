#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-multipage-mixed-sizes
# @title: Pillow TIFF multipage save with three differently sized RGB pages
# @description: Saves a three-page TIFF where each page has a distinct (width, height) and a distinct fill color via save_all+append_images, then walks the frames with seek() and asserts that n_frames is 3, each frame's size matches its expected dimensions in order, each frame stays in mode RGB, and the upper-left pixel of each page returns the expected fill color, demonstrating Pillow propagates per-IFD geometry through libtiff.
# @timeout: 180
# @tags: usage, image, python, multipage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/mixed.tiff"
import sys
from PIL import Image

path = sys.argv[1]
expected = [
    ((10, 7), (240, 20, 30)),
    ((6, 12), (20, 200, 40)),
    ((5, 5), (10, 30, 220)),
]

pages = [Image.new("RGB", size, color) for size, color in expected]
pages[0].save(path, save_all=True, append_images=pages[1:])

with Image.open(path) as im:
    assert getattr(im, "n_frames", 1) == 3, im.n_frames
    for index, (size, color) in enumerate(expected):
        im.seek(index)
        assert im.tell() == index, (index, im.tell())
        assert im.size == size, (index, im.size, size)
        assert im.mode == "RGB", (index, im.mode)
        assert im.getpixel((0, 0)) == color, (index, im.getpixel((0, 0)), color)
        assert im.getpixel((size[0] - 1, size[1] - 1)) == color
    print("mixed-sizes", [s for s, _ in expected])
PY
