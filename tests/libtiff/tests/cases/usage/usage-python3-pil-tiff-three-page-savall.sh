#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-three-page-savall
# @title: Pillow TIFF three-page save_all
# @description: Writes a three-page TIFF with save_all and append_images, then verifies n_frames and per-frame size.
# @timeout: 180
# @tags: usage, image, python, multipage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/three.tiff"
from PIL import Image
import sys

path = sys.argv[1]
page_a = Image.new("RGB", (4, 4), "red")
page_b = Image.new("RGB", (4, 4), "green")
page_c = Image.new("RGB", (4, 4), "blue")
page_a.save(path, save_all=True, append_images=[page_b, page_c])

with Image.open(path) as im:
    assert getattr(im, "n_frames", 1) == 3, im.n_frames
    seen = []
    for index in range(im.n_frames):
        im.seek(index)
        assert im.tell() == index, (index, im.tell())
        assert im.size == (4, 4), im.size
        assert im.mode == "RGB", im.mode
        seen.append(index)
    assert seen == [0, 1, 2], seen
    print("frames", im.n_frames)
PY
