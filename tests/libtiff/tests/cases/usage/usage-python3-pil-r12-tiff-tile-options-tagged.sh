#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-tile-options-tagged
# @title: tiffcp converts a Pillow stripped TIFF into a tiled TIFF with TileWidth/TileLength=64
# @description: Saves an RGB TIFF with Pillow (stripped layout) and runs libtiff's tiffcp -t -w 64 -l 64 to convert it into a tiled TIFF, then asserts tiffinfo reports "Tile Width: 64" and "Tile Length: 64" in the output metadata. (Pillow's TIFF writer does not honour a "tile" save kwarg; tiffcp is the libtiff-side surface for producing tiled imagery and is what this test exercises.)
# @timeout: 60
# @tags: usage, tiff, python, tiled
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/stripped.tif"
dst="$tmpdir/tiled.tif"

python3 - "$src" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (128, 128), (40, 80, 120))
img.save(sys.argv[1], 'TIFF', compression='tiff_lzw')
PY

validator_require_file "$src"
tiffcp -t -w 64 -l 64 -c lzw "$src" "$dst"
validator_require_file "$dst"

tiffinfo "$dst" >"$tmpdir/info.out"
grep -Eq 'Tile Width: 64' "$tmpdir/info.out"
grep -Eq 'Tile Length: 64' "$tmpdir/info.out"
