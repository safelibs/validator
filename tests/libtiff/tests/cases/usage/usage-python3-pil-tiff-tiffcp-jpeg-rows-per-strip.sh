#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcp-jpeg-rows-per-strip
# @title: Pillow TIFF tiffcp -c jpeg with rows-per-strip
# @description: Writes a stripped TIFF with Pillow, converts it to JPEG-compressed TIFF with tiffcp -c jpeg -r 16, and verifies Compression=7 and RowsPerStrip=16 on reload.
# @timeout: 180
# @tags: usage, image, python, compression, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src.tiff"
out="$tmpdir/jpeg.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

size = (64, 48)
pixels = [
    ((x * 3) % 256, (y * 5) % 256, ((x + y) * 7) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$src"
tiffcp -c jpeg -r 16 "$src" "$out"
validator_require_file "$out"

python3 - <<'PY' "$out"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    comp = im.tag_v2.get(259)
    rps = im.tag_v2.get(278)
    assert comp == 7, ("compression", comp)
    assert rps == 16, ("rowsperstrip", rps)
    assert im.size == (64, 48), im.size
    assert im.mode in ("RGB", "YCbCr"), im.mode
    print("jpeg-rps", comp, rps, im.mode)
PY
