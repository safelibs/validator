#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcp-lzw-roundtrip
# @title: Pillow TIFF tiffcp -c lzw conversion
# @description: Writes an uncompressed TIFF with Pillow, converts it to LZW with tiffcp -c lzw, and verifies the Compression tag (259) is 5 and pixel data is preserved.
# @timeout: 180
# @tags: usage, image, python, compression, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raw="$tmpdir/raw.tiff"
lzw="$tmpdir/lzw.tiff"

python3 - <<'PY' "$raw"
import sys
from PIL import Image

size = (24, 18)
pixels = [
    ((x * 7) % 256, (y * 11) % 256, ((x + y) * 13) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1], compression="raw")
PY

validator_require_file "$raw"
tiffcp -c lzw "$raw" "$lzw"
validator_require_file "$lzw"

python3 - <<'PY' "$raw" "$lzw"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as a, Image.open(sys.argv[2]) as b:
    a.load()
    b.load()
    assert a.size == b.size == (24, 18), (a.size, b.size)
    assert a.mode == b.mode == "RGB", (a.mode, b.mode)
    comp = b.tag_v2.get(259)
    assert comp == 5, ("compression", comp)
    assert list(a.getdata()) == list(b.getdata()), "pixel data mismatch after lzw conversion"
    print("lzw", comp, b.size)
PY
