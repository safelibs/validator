#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-tiff-load-end-frees-tile-state
# @title: Pillow load() on a TIFF clears the tile list so a subsequent load() is a no-op
# @description: Saves a 4x4 mode-L TIFF, opens it, asserts that im.tile is non-empty before load(), then calls load() and asserts im.tile is now empty (decode complete), confirming libtiff strip/tile decode state is consumed exactly once by Pillow.
# @timeout: 60
# @tags: usage, tiff, python, load, tile-state, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/tile.tif" <<'PY'
import sys
from PIL import Image

Image.new('L', (4, 4), 50).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    pre = list(im.tile)
    assert len(pre) >= 1, pre
    im.load()
    post = list(im.tile)
    assert post == [], post
    print('ok pre_tiles=%d post_tiles=%d' % (len(pre), len(post)))
PY
