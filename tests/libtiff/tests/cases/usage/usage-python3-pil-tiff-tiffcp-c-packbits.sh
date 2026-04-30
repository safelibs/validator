#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcp-c-packbits
# @title: Pillow TIFF tiffcp -c packbits
# @description: Writes an uncompressed TIFF with Pillow, converts it with tiffcp -c packbits, and verifies the Compression tag (259) becomes 32773 (PackBits) and pixel data is preserved.
# @timeout: 180
# @tags: usage, image, python, compression, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raw="$tmpdir/raw.tiff"
pb="$tmpdir/pb.tiff"

python3 - <<'PY' "$raw"
import sys
from PIL import Image

path = sys.argv[1]
size = (32, 20)
pixels = [
    ((x * 7) % 256, (y * 11) % 256, ((x + y) * 3) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(path, compression="raw")
PY

validator_require_file "$raw"
tiffcp -c packbits "$raw" "$pb"
validator_require_file "$pb"

python3 - <<'PY' "$raw" "$pb"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as a, Image.open(sys.argv[2]) as b:
    a.load(); b.load()
    assert a.size == b.size == (32, 20), (a.size, b.size)
    assert a.mode == b.mode == "RGB", (a.mode, b.mode)
    comp = b.tag_v2.get(259)
    assert comp == 32773, ("compression", comp)
    assert list(a.getdata()) == list(b.getdata()), "pixel data mismatch after packbits"
    print("packbits", comp, b.size)
PY
