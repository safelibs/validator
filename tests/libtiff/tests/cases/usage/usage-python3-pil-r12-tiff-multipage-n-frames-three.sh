#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-multipage-n-frames-three
# @title: PIL Image.n_frames reports 3 for a three-page TIFF
# @description: Builds a 3-page TIFF using save_all and append_images and verifies Image.n_frames == 3 on reopen, reflecting the libtiff multi-directory layout discovered by Pillow.
# @timeout: 60
# @tags: usage, tiff, python, multipage, frames
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/multi.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
a = Image.new('RGB', (16, 16), (255, 0, 0))
b = Image.new('RGB', (16, 16), (0, 255, 0))
c = Image.new('RGB', (16, 16), (0, 0, 255))
a.save(sys.argv[1], 'TIFF', save_all=True, append_images=[b, c])

with Image.open(sys.argv[1]) as im:
    assert im.n_frames == 3, ('n_frames', im.n_frames)
PY
