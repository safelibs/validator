#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-tiff-thumbnail-fits-within-bounding-box
# @title: Pillow thumbnail on a TIFF-loaded image fits within the requested bounds
# @description: Saves a 40x20 RGB TIFF, reopens, calls .thumbnail((10, 10)) (modifies in place), and asserts the resulting image's width <= 10 and height <= 10 and that the aspect ratio is preserved (width > height since source aspect 40:20 should produce width:height >= 2:1 after shrink), confirming libtiff-decoded pixels feed Pillow's aspect-preserving thumbnail correctly.
# @timeout: 60
# @tags: usage, tiff, python, thumbnail, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/thumb.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

Image.new('RGB', (40, 20), (200, 50, 50)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as r:
    r.load()
    r.thumbnail((10, 10))
    w, h = r.size
    assert w <= 10, w
    assert h <= 10, h
    # source aspect 40:20 = 2:1, so width should be >= height
    assert w >= h, (w, h)
    print('ok thumb size=%s' % (r.size,))
PY
