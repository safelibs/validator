#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-tile-options-tagged
# @title: PIL TIFF saved with explicit tile=(64, 64) tags TileWidth and TileLength
# @description: Saves an RGB TIFF with Pillow using libtiff tile=(64,64) options and verifies tag_v2[322] TileWidth == 64 and tag_v2[323] TileLength == 64 are present in the readback metadata, asserting the tiled write path.
# @timeout: 60
# @tags: usage, tiff, python, tiled
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/tiled.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (128, 128), (40, 80, 120))
img.save(sys.argv[1], 'TIFF', compression='tiff_lzw', tile=(64, 64))

with Image.open(sys.argv[1]) as im:
    im.load()
    tw = im.tag_v2.get(322)
    tl = im.tag_v2.get(323)
    assert tw == 64, ('TileWidth', tw)
    assert tl == 64, ('TileLength', tl)
PY

tiffinfo "$path" >"$tmpdir/info.out"
grep -E 'Tile Width: 64' "$tmpdir/info.out" >/dev/null
grep -E 'Tile Length: 64' "$tmpdir/info.out" >/dev/null
