#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-rowsperstrip-explicit
# @title: Pillow TIFF explicit RowsPerStrip via tiffcp -r repackage
# @description: Writes a TIFF with Pillow (Pillow does not support multistrip output via the tiffinfo dict; that path raises NotImplementedError), repackages it through tiffcp -r 8 to force RowsPerStrip = 8, and verifies the saved RowsPerStrip tag (278) matches on reload.
# @timeout: 180
# @tags: usage, image, python, strips
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src.tiff"
out="$tmpdir/rps.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

path = sys.argv[1]
size = (40, 96)
pixels = [
    ((x * 6) % 256, (y * 9) % 256, ((x + y) * 4) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(path)
PY

# Pillow's TIFF writer cannot lay down multiple strips itself. Use tiffcp
# to repackage the single-strip Pillow output with RowsPerStrip = 8, which
# is what the test actually wants to verify Pillow can read back.
tiffcp -r 8 "$src" "$out"
validator_require_file "$out"

python3 - <<'PY' "$out"
import sys
from PIL import Image

path = sys.argv[1]
with Image.open(path) as reopened:
    reopened.load()
    rps_raw = reopened.tag_v2.get(278)
    rps = rps_raw[0] if hasattr(rps_raw, "__len__") else rps_raw
    assert rps == 8, ("rows_per_strip", rps_raw)
    assert reopened.size == (40, 96), reopened.size
    assert reopened.mode == "RGB", reopened.mode
    print("rps", rps, reopened.size)
PY
