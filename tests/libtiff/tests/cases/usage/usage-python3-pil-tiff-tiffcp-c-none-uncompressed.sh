#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcp-c-none-uncompressed
# @title: Pillow TIFF tiffcp -c none uncompressed
# @description: Writes a Deflate-compressed TIFF with Pillow, then converts it with tiffcp -c none and verifies the Compression tag (259) becomes 1 (no compression) and pixel data round-trips byte-for-byte.
# @timeout: 180
# @tags: usage, image, python, compression, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/deflate.tiff"
none="$tmpdir/none.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

path = sys.argv[1]
size = (28, 18)
pixels = [
    ((x * 9) % 256, (y * 13) % 256, ((x + y) * 5) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(path, compression="tiff_adobe_deflate")
PY

validator_require_file "$src"
tiffcp -c none "$src" "$none"
validator_require_file "$none"

python3 - <<'PY' "$src" "$none"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as a, Image.open(sys.argv[2]) as b:
    a.load(); b.load()
    assert a.size == b.size == (28, 18), (a.size, b.size)
    assert a.mode == b.mode == "RGB", (a.mode, b.mode)
    comp = b.tag_v2.get(259)
    assert comp == 1, ("compression", comp)
    assert list(a.getdata()) == list(b.getdata()), "pixel data mismatch after -c none"
    print("none", comp, b.size)
PY
