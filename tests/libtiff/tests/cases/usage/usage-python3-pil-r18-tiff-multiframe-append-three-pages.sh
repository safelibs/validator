#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-tiff-multiframe-append-three-pages
# @title: Pillow TIFF save_all with two appended frames produces a 3-page n_frames
# @description: Writes a multipage TIFF by calling Image.save with save_all=True and an append_images list of two additional frames, reopens the resulting file with Pillow, and asserts im.n_frames equals exactly 3, confirming libtiff multi-page IFD chaining round-trips through Pillow's append API.
# @timeout: 60
# @tags: usage, tiff, python, multiframe, save_all, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/multi.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
a = Image.new('RGB', (4, 4), (255, 0, 0))
b = Image.new('RGB', (4, 4), (0, 255, 0))
c = Image.new('RGB', (4, 4), (0, 0, 255))
a.save(sys.argv[1], 'TIFF', save_all=True, append_images=[b, c])

with Image.open(sys.argv[1]) as im:
    n = im.n_frames
    assert n == 3, ('n_frames', n)
print('ok n_frames=%d' % n)
PY
