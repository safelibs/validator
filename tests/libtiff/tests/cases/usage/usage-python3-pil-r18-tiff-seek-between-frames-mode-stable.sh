#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-tiff-seek-between-frames-mode-stable
# @title: Pillow seeks between TIFF frames keeping the same mode and size across pages
# @description: Builds a two-page TIFF where both frames are RGB and 5x5, calls im.seek(0) then im.seek(1) on the reopened file, and asserts both frames report the same mode "RGB" and the same size (5, 5), confirming libtiff IFD navigation preserves per-page metadata reported by Pillow.
# @timeout: 60
# @tags: usage, tiff, python, multiframe, seek, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/seek.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
p1 = Image.new('RGB', (5, 5), (1, 2, 3))
p2 = Image.new('RGB', (5, 5), (4, 5, 6))
p1.save(sys.argv[1], 'TIFF', save_all=True, append_images=[p2])

with Image.open(sys.argv[1]) as im:
    im.seek(0)
    im.load()
    assert im.mode == 'RGB' and im.size == (5, 5), ('frame0', im.mode, im.size)
    im.seek(1)
    im.load()
    assert im.mode == 'RGB' and im.size == (5, 5), ('frame1', im.mode, im.size)
print('ok seek both frames RGB 5x5')
PY
