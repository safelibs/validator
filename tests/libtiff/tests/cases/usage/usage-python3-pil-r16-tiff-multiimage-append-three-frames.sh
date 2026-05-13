#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-tiff-multiimage-append-three-frames
# @title: PIL save_all append_images writes a 3-frame TIFF readable via seek
# @description: Saves a TIFF with save_all=True and append_images=[f2, f3], reopens with Pillow, asserts n_frames is 3, seeks to frames 0, 1, and 2 and asserts each frame's mode is L and the per-frame fill colour matches the originals via getpixel((0,0)).
# @timeout: 60
# @tags: usage, tiff, python, multiframe
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/multi3.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

frames = [Image.new('L', (4, 4), c) for c in (10, 100, 200)]
frames[0].save(sys.argv[1], 'TIFF', save_all=True, append_images=frames[1:])

with Image.open(sys.argv[1]) as im:
    assert getattr(im, 'n_frames', None) == 3, ('n_frames', getattr(im, 'n_frames', None))
    for i, expected in enumerate((10, 100, 200)):
        im.seek(i)
        im.load()
        assert im.mode == 'L', ('mode', i, im.mode)
        v = im.getpixel((0, 0))
        assert v == expected, ('pixel', i, v, expected)
PY
