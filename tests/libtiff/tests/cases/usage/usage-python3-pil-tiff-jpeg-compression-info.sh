#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-jpeg-compression-info
# @title: Pillow TIFF JPEG compression info
# @description: Writes a JPEG-compressed RGB TIFF and verifies the Compression tag, info dict, and reopened image dimensions.
# @timeout: 180
# @tags: usage, image, python, compression, jpeg
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/jpeg.tiff"
import sys
from PIL import Image

path = sys.argv[1]
size = (32, 16)
pixels = [
    ((x * 7) % 256, (y * 11 + 30) % 256, ((x + y) * 5) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(path, compression="jpeg")

with open(path, "rb") as fh:
    head = fh.read(4)
assert head[:2] in (b"II", b"MM"), head

with Image.open(path) as reopened:
    reopened.load()
    compression = reopened.info.get("compression")
    tag = reopened.tag_v2.get(259)
    assert compression == "jpeg", compression
    assert tag == 7, tag
    assert reopened.size == size, reopened.size
    assert reopened.mode in ("RGB", "YCbCr"), reopened.mode
    print("jpeg", compression, tag, reopened.size)
PY
