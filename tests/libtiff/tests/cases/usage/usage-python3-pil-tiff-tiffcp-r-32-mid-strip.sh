#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcp-r-32-mid-strip
# @title: Pillow TIFF tiffcp -r 32 mid-size strip layout
# @description: Writes a 40x100 TIFF with Pillow (single strip), repackages with tiffcp -r 32 to produce four strips (32+32+32+4 rows), and verifies RowsPerStrip = 32 and exactly four strips on the output via tiffinfo -s plus Pillow tag readback.
# @timeout: 180
# @tags: usage, image, python, strips, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src.tiff"
out="$tmpdir/r32.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

size = (40, 100)
pixels = [
    ((x * 4) % 256, (y * 5) % 256, ((x + y) * 7) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$src"

tiffcp -r 32 "$src" "$out"
validator_require_file "$out"

report="$tmpdir/info.txt"
tiffinfo -s "$out" >"$report"
validator_assert_contains "$report" "Rows/Strip: 32"
# 100 rows / 32 -> 4 strips (last is partial).
validator_assert_contains "$report" "4 Strips:"

python3 - <<'PY' "$out"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    rps_raw = im.tag_v2.get(278)
    rps = rps_raw[0] if hasattr(rps_raw, "__len__") else rps_raw
    assert rps == 32, ("rowsperstrip", rps_raw)
    offsets = im.tag_v2.get(273)
    counts = im.tag_v2.get(279)
    assert offsets is not None and counts is not None
    n_off = len(offsets) if hasattr(offsets, "__len__") else 1
    n_cnt = len(counts) if hasattr(counts, "__len__") else 1
    assert n_off == 4, ("strip offsets", n_off, offsets)
    assert n_cnt == 4, ("strip counts", n_cnt, counts)
    assert im.size == (40, 100), im.size
    assert im.mode == "RGB", im.mode
    print("r32", rps, n_off)
PY
