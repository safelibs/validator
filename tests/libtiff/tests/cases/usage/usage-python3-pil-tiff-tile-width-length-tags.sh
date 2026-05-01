#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tile-width-length-tags
# @title: Pillow TIFF tiled layout tile width and length tags
# @description: Pillow saves a stripped TIFF, tiffcp repackages it as 32x32 tiles, and Pillow reload exposes tag_v2 TileWidth (322) and TileLength (323) both equal to 32 plus consistent TileOffsets and TileByteCounts arrays.
# @timeout: 180
# @tags: usage, image, python, tile
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stripped="$tmpdir/strips.tiff"
tiled="$tmpdir/tiled.tiff"

python3 - <<'PY' "$stripped"
from PIL import Image
import sys

size = (96, 64)
pixels = [
    ((x * 3) % 256, (y * 5) % 256, ((x ^ y) * 7) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$stripped"
tiffcp -t -w 32 -l 32 "$stripped" "$tiled"
validator_require_file "$tiled"

python3 - <<'PY' "$tiled"
from PIL import Image
import sys

with Image.open(sys.argv[1]) as im:
    im.load()
    tw = im.tag_v2.get(322)
    tl = im.tag_v2.get(323)
    offsets = im.tag_v2.get(324)
    byte_counts = im.tag_v2.get(325)
    assert tw == 32, tw
    assert tl == 32, tl
    assert offsets is not None and byte_counts is not None
    n_off = len(offsets) if hasattr(offsets, "__len__") else 1
    n_bc = len(byte_counts) if hasattr(byte_counts, "__len__") else 1
    assert n_off == n_bc, (n_off, n_bc)
    # 96/32 * 64/32 = 6 tiles.
    assert n_off == 6, n_off
    assert im.size == (96, 64), im.size
    print("tiles", tw, tl, n_off)
PY
