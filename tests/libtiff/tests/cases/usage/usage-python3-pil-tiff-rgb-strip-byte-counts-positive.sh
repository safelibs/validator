#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-rgb-strip-byte-counts-positive
# @title: Pillow TIFF strip byte counts sanity for raw RGB
# @description: Saves a 32x16 RGB TIFF with raw (uncompressed) compression and verifies that StripByteCounts (279) sums to width*height*3 = 1536, matching the raw payload size for an 8-bit-per-sample chunky 24-bit TIFF.
# @timeout: 180
# @tags: usage, image, python, sizing
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/raw.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image

size = (32, 16)
pixels = [
    ((x * 3) & 0xFF, (y * 5) & 0xFF, ((x ^ y) * 7) & 0xFF)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1], compression="raw")

with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    bc = reopened.tag_v2.get(279)
    if hasattr(bc, "__len__"):
        total = sum(int(v) for v in bc)
    else:
        total = int(bc)
    assert total == 32 * 16 * 3, (total, bc)
    bps = reopened.tag_v2.get(258)
    bps_seq = bps if hasattr(bps, "__len__") else (bps,)
    assert all(int(b) == 8 for b in bps_seq), bps
    spp = reopened.tag_v2.get(277)
    assert spp == 3, spp
    compression = reopened.tag_v2.get(259)
    assert compression == 1, compression  # 1 = no compression
    print("raw", total, list(bps_seq), spp)
PY
