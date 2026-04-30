#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-rowsperstrip-tag-tiffcp-r-16
# @title: Pillow TIFF RowsPerStrip = 16 via tiffcp -r 16 repackage
# @description: Writes a 40x80 single-strip TIFF with Pillow (Pillow itself raises NotImplementedError when asked to emit multistrip output, so the layout is forced via tiffcp -r 16 instead) then verifies the repackaged file has Rows/Strip=16, exactly five strips, and Pillow reads back the RowsPerStrip tag (278) as 16.
# @timeout: 180
# @tags: usage, image, python, strips, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src.tiff"
out="$tmpdir/repack.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

path = sys.argv[1]
size = (40, 80)
pixels = [
    ((x * 5) % 256, (y * 7) % 256, ((x + y) * 9) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
# Pillow can only emit a single-strip TIFF here; tiffcp -r 16 below
# rewrites it into the multistrip form we actually want to validate.
image.save(path)
PY

validator_require_file "$src"

# Force multistrip layout via tiffcp -r 16. 80 rows / 16 = 5 strips.
tiffcp -r 16 "$src" "$out"
validator_require_file "$out"

report="$tmpdir/info.txt"
tiffinfo -s "$out" >"$report"
validator_assert_contains "$report" "Rows/Strip: 16"
validator_assert_contains "$report" "5 Strips:"

python3 - <<'PY' "$out"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    rps_raw = im.tag_v2.get(278)
    rps = rps_raw[0] if hasattr(rps_raw, "__len__") else rps_raw
    assert rps == 16, ("rowsperstrip", rps_raw)
    assert im.size == (40, 80), im.size
    assert im.mode == "RGB", im.mode
    print("rps16", rps, im.size)
PY
