#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-tiff-multipage-save-all-five-frames
# @title: PIL TIFF save_all + append_images builds a 5-frame TIFF
# @description: Saves five distinct solid-color RGB pages to a single TIFF using save_all=True with append_images of length four, then verifies Image.n_frames == 5 on reopen, asserting libtiff records all five IFDs and Pillow walks them.
# @timeout: 60
# @tags: usage, tiff, python, multipage, save_all
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/five.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (200, 200, 0), (50, 50, 50)]
frames = [Image.new('RGB', (12, 8), c) for c in colors]
frames[0].save(sys.argv[1], 'TIFF', save_all=True, append_images=frames[1:])

with Image.open(sys.argv[1]) as im:
    assert im.n_frames == 5, ('n_frames', im.n_frames)
PY
