#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-tiff-default-append-false-overwrites
# @title: PIL TIFF save without save_all writes a single-frame file even after a prior multi-frame save
# @description: Writes a 3-frame multi-page TIFF with save_all=True, then re-saves to the same path with a single image and the default save_all=False, reopens with Pillow, asserts n_frames is 1, mode is L, and the only frame's (0,0) pixel matches the single-image value — exercising Pillow's default non-append save behaviour atop libtiff.
# @timeout: 60
# @tags: usage, tiff, python, multiframe
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/single.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

multi = [Image.new('L', (4, 4), c) for c in (10, 20, 30)]
multi[0].save(sys.argv[1], 'TIFF', save_all=True, append_images=multi[1:])

# Now overwrite with a single frame, default save_all=False.
Image.new('L', (4, 4), 99).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert getattr(im, 'n_frames', 1) == 1, ('n_frames', im.n_frames)
    assert im.mode == 'L', ('mode', im.mode)
    assert im.getpixel((0, 0)) == 99, ('pix', im.getpixel((0, 0)))
PY
