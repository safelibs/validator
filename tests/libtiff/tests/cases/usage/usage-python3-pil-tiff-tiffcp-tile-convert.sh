#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcp-tile-convert
# @title: Pillow TIFF strip to tile via tiffcp
# @description: Writes a stripped TIFF with Pillow then converts it to a tiled TIFF with tiffcp and verifies TileWidth/TileLength via Pillow.
# @timeout: 180
# @tags: usage, image, python, tiles
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

strip="$tmpdir/strip.tiff"
tiled="$tmpdir/tiled.tiff"

python3 - <<'PY' "$strip"
from PIL import Image
import sys

size = (64, 48)
pixels = [
    ((x * 3) % 256, (y * 5) % 256, ((x + y) * 7) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$strip"
tiffcp -t -w 16 -l 16 "$strip" "$tiled"
validator_require_file "$tiled"

python3 - <<'PY' "$tiled"
from PIL import Image
import sys

with Image.open(sys.argv[1]) as im:
    im.load()
    tile_width = im.tag_v2.get(322)
    tile_length = im.tag_v2.get(323)
    assert tile_width == 16, tile_width
    assert tile_length == 16, tile_length
    assert 278 not in im.tag_v2, "expected no RowsPerStrip in tiled TIFF"
    assert im.size == (64, 48), im.size
    assert im.mode == "RGB", im.mode
    print("tile", tile_width, tile_length, im.size)
PY
