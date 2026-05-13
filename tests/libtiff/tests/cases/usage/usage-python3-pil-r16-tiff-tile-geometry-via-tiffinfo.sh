#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-tiff-tile-geometry-via-tiffinfo
# @title: Pillow stripped TIFF re-tiled to 64x64 reports matching tile geometry via tiffinfo
# @description: Writes a 128x96 RGB stripped TIFF with Pillow, runs libtiff's tiffcp -t -w 64 -l 64 to produce a tiled variant, and asserts tiffinfo reports both "Tile Width: 64" and "Tile Length: 64", relying on tiffinfo as the authoritative source for tile geometry instead of PIL tag_v2.
# @timeout: 60
# @tags: usage, tiff, python, tile, tiffinfo
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/strip128.tif"
tiled="$tmpdir/tile64.tif"

python3 - "$src" <<'PY'
import sys
from PIL import Image
w, h = 128, 96
img = Image.new('RGB', (w, h))
img.putdata([((x % 256), ((x + y) % 256), (y % 256)) for y in range(h) for x in range(w)])
img.save(sys.argv[1], 'TIFF')
PY

validator_require_file "$src"
tiffcp -t -w 64 -l 64 "$src" "$tiled"
validator_require_file "$tiled"

tiffinfo "$tiled" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Tile Width: 64'
validator_assert_contains "$tmpdir/info.txt" 'Tile Length: 64'
