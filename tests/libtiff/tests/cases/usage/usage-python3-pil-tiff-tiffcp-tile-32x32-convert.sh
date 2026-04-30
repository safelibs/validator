#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcp-tile-32x32-convert
# @title: Pillow TIFF tiffcp 32x32 tile conversion
# @description: Writes a stripped TIFF with Pillow then converts it to a 32x32-tiled TIFF with tiffcp -t -w 32 -l 32 and verifies tile geometry via PIL tag_v2 and tiffinfo.
# @timeout: 180
# @tags: usage, image, python, tiles, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/strip.tiff"
tiled="$tmpdir/tiled32.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

size = (96, 80)
pixels = [
    ((x * 2) % 256, (y * 3) % 256, ((x + y) * 5) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$src"
tiffcp -t -w 32 -l 32 "$src" "$tiled"
validator_require_file "$tiled"

report="$tmpdir/info.txt"
tiffinfo "$tiled" >"$report"
validator_assert_contains "$report" "Tile Width:"
validator_assert_contains "$report" "Tile Length:"
validator_assert_contains "$report" "32"

python3 - <<'PY' "$tiled"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    tw = im.tag_v2.get(322)
    tl = im.tag_v2.get(323)
    assert tw == 32, tw
    assert tl == 32, tl
    assert 278 not in im.tag_v2, "tiled TIFF must not have RowsPerStrip"
    assert im.size == (96, 80), im.size
    assert im.mode == "RGB", im.mode
    print("tile32", tw, tl, im.size)
PY
