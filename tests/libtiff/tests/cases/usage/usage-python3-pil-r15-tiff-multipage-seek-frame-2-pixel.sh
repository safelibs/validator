#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-tiff-multipage-seek-frame-2-pixel
# @title: PIL TIFF save_all + seek(2) reaches the third page with its expected color
# @description: Saves three distinct solid-color RGB pages (red, green, blue) to a single TIFF using save_all=True with append_images of length two, then verifies on reopen that n_frames == 3, im.seek(2) succeeds, and getpixel((0, 0)) of the third frame returns (0, 0, 255), asserting libtiff records all three IFDs and Pillow can navigate to the third frame and recover its pixel data.
# @timeout: 60
# @tags: usage, tiff, python, multipage, seek
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/three.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255)]
frames = [Image.new('RGB', (10, 6), c) for c in colors]
frames[0].save(sys.argv[1], 'TIFF', save_all=True, append_images=frames[1:])

with Image.open(sys.argv[1]) as im:
    assert im.n_frames == 3, ('n_frames', im.n_frames)
    im.seek(2)
    px = im.getpixel((0, 0))
    assert px == (0, 0, 255), ('frame 2 pixel', px)
PY
