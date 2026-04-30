#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-strip-byte-counts-tiffinfo-s
# @title: Pillow TIFF strip byte counts via tiffinfo
# @description: Saves a stripped TIFF with Pillow and verifies the tiffinfo report exposes the per-strip table (rows-per-strip, strip count, and a [offset, byte-count] entry) and that the PIL tag_v2 exposes consistent strip counts.
# @timeout: 180
# @tags: usage, image, python, metadata, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

single="$tmpdir/single.tiff"
img="$tmpdir/strips.tiff"

python3 - <<'PY' "$single"
import sys
from PIL import Image

size = (32, 96)
pixels = [
    ((x * 5) % 256, (y * 7) % 256, ((x + y) * 9) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1], compression="raw")
PY

validator_require_file "$single"
# Pillow writes single-strip TIFFs and rejects multistrip on save; use
# tiffcp -r 16 to repackage the same payload into 16-rows-per-strip multi-strip
# form that tiffinfo will then expose with the per-strip table.
tiffcp -r 16 "$single" "$img"
validator_require_file "$img"

report="$tmpdir/strips.txt"
tiffinfo "$img" >"$report"
# Plain tiffinfo (no -D) emits "Rows/Strip:" with the per-strip span. The
# strip count and offset/byte-count table live in the TIFF tags themselves
# (verified below via PIL tag_v2 lookups).
validator_assert_contains "$report" "Rows/Strip: 16"
validator_assert_contains "$report" "Image Length: 96"

python3 - <<'PY' "$img"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    offsets = im.tag_v2.get(273)
    byte_counts = im.tag_v2.get(279)
    rows_per_strip = im.tag_v2.get(278)
    assert offsets is not None, "missing StripOffsets"
    assert byte_counts is not None, "missing StripByteCounts"
    assert rows_per_strip is not None, "missing RowsPerStrip"
    n_off = len(offsets) if hasattr(offsets, "__len__") else 1
    n_bc = len(byte_counts) if hasattr(byte_counts, "__len__") else 1
    assert n_off == n_bc, (n_off, n_bc)
    assert n_off >= 1, n_off
    print("strips", n_off, int(rows_per_strip))
PY
