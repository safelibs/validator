#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-tiff-multiframe-tell-resets-after-seek-zero
# @title: Pillow TIFF multi-page tell() returns to 0 after seeking back from a later frame
# @description: Saves a 4-page TIFF where each page has a distinct fill color, opens the file with Pillow, asserts initial im.tell() is 0, seeks to frame 2 and asserts im.tell() returns 2, then seeks to frame 0 and asserts im.tell() returns 0 again, also asserts the reloaded pixel at (0,0) on frame 0 matches the original red color, confirming libtiff random-access page navigation.
# @timeout: 60
# @tags: usage, tiff, python, multiframe, tell, seek, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/mp.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)]
frames = [Image.new('RGB', (4, 4), c) for c in colors]
frames[0].save(sys.argv[1], 'TIFF', save_all=True, append_images=frames[1:])

with Image.open(sys.argv[1]) as im:
    assert im.tell() == 0, ('initial tell', im.tell())
    im.seek(2)
    assert im.tell() == 2, ('after seek(2)', im.tell())
    im.seek(0)
    assert im.tell() == 0, ('after seek(0)', im.tell())
    im.load()
    px = im.getpixel((0, 0))
    assert px[:3] == (255, 0, 0), ('frame 0 color', px)
print('ok seek/tell roundtrip')
PY
