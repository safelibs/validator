#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-ccitt-rle-bilevel-compression
# @title: Pillow TIFF tiff_ccitt CCITT modified Huffman RLE compression on 1-bit image
# @description: Saves a 1-bit (mode "1") bilevel TIFF with compression="tiff_ccitt" (CCITT modified Huffman run-length encoding, Compression tag value 2) and verifies the reopened TIFF reports info["compression"]=="tiff_ccitt", Compression tag (259) equals 2, the mode stays "1", BitsPerSample (258) equals 1, and the bilevel pixel pattern survives the round-trip exactly.
# @timeout: 180
# @tags: usage, image, python, compression, ccitt
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/ccitt_rle.tiff"
import sys
from PIL import Image


def first(value):
    if isinstance(value, tuple):
        return value[0]
    return value


path = sys.argv[1]
size = (32, 16)
# Vertical stripes: alternating columns of 0/255.
pixels = [255 if x % 2 == 0 else 0 for y in range(size[1]) for x in range(size[0])]
image = Image.new("L", size)
image.putdata(pixels)
image = image.convert("1")
expected_bytes = image.tobytes()
image.save(path, compression="tiff_ccitt")

with Image.open(path) as reopened:
    reopened.load()
    compression = reopened.info.get("compression")
    tag = first(reopened.tag_v2.get(259))
    bps = first(reopened.tag_v2.get(258))
    assert compression == "tiff_ccitt", ("info compression", compression)
    assert tag == 2, ("Compression tag", reopened.tag_v2.get(259))
    assert bps == 1, ("BitsPerSample", reopened.tag_v2.get(258))
    assert reopened.mode == "1", reopened.mode
    assert reopened.size == size, reopened.size
    assert reopened.tobytes() == expected_bytes, "bilevel pattern diverged"
    print("ccitt-rle", compression, tag, reopened.size)
PY
