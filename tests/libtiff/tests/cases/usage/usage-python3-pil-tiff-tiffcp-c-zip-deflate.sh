#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcp-c-zip-deflate
# @title: Pillow TIFF tiffcp -c zip deflate alias
# @description: Writes an uncompressed TIFF with Pillow, converts it with tiffcp -c zip (the deflate alias), and verifies the Compression tag (259) is 8 (Deflate/Adobe Deflate) and pixels are preserved.
# @timeout: 180
# @tags: usage, image, python, compression, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raw="$tmpdir/raw.tiff"
zip="$tmpdir/zip.tiff"

python3 - <<'PY' "$raw"
import sys
from PIL import Image

path = sys.argv[1]
size = (28, 22)
pixels = [
    ((x * 13) % 256, (y * 17) % 256, ((x + y) * 9) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(path, compression="raw")
PY

validator_require_file "$raw"
tiffcp -c zip "$raw" "$zip"
validator_require_file "$zip"

python3 - <<'PY' "$raw" "$zip"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as a, Image.open(sys.argv[2]) as b:
    a.load(); b.load()
    assert a.size == b.size == (28, 22), (a.size, b.size)
    assert a.mode == b.mode == "RGB", (a.mode, b.mode)
    comp = b.tag_v2.get(259)
    # 8 = Deflate; some libtiff builds report Adobe Deflate (32946) for -c zip.
    assert comp in (8, 32946), ("compression", comp)
    assert list(a.getdata()) == list(b.getdata()), "pixel data mismatch after -c zip"
    print("zip", comp, b.size)
PY
