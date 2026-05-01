#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-tile-decoder-info
# @title: Pillow JPEG tile decoder descriptor
# @description: Opens a JPEG with Pillow without forcing a load and verifies im.tile advertises a single ('jpeg', ...) decoder tile spanning the full image, the wiring Pillow uses to drive libjpeg-turbo.
# @timeout: 180
# @tags: usage, jpeg, python, decoder
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

tmpdir = Path(sys.argv[1])
W, H = 48, 32
src = Image.new('RGB', (W, H))
src.putdata([((x * 5) & 255, (y * 9) & 255, ((x ^ y) * 3) & 255)
             for y in range(H) for x in range(W)])

p = tmpdir / 'tile.jpg'
src.save(p, 'JPEG', quality=80)

# Open without calling load() so the tile descriptor is still populated.
im = Image.open(p)
try:
    assert im.format == 'JPEG'
    tile = im.tile
    assert isinstance(tile, list) and len(tile) == 1, f'unexpected tile: {tile!r}'
    decoder, extents, offset, args = tile[0]
    assert decoder == 'jpeg', f'expected jpeg decoder, got {decoder!r}'
    assert extents == (0, 0, W, H), f'tile extents {extents!r} != full image'
    assert isinstance(offset, int) and offset >= 0
    # args is (mode, layout); RGB JPEGs encode as ('RGB', '') in Pillow 10.x.
    assert args[0] == 'RGB', f'unexpected decoder mode {args!r}'
    print('tile', tile)
    im.load()
    # After load() Pillow clears tile to signal the image is materialised.
    assert im.tile == [], f'tile not cleared post-load: {im.tile!r}'
finally:
    im.close()
PYCASE
