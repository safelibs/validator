#!/usr/bin/env bash
# @testcase: usage-python3-pil-deflate-tiff
# @title: Pillow Deflate TIFF save
# @description: Saves a Deflate-compressed TIFF with Pillow and verifies libtiff-backed reload behavior.
# @timeout: 180
# @tags: usage, image, python, compression
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/deflate.tiff"
from PIL import Image
import sys

size = (5, 4)
pixels = [
    ((x * 31 + y * 7) % 256, (x * 17 + y * 29) % 256, (x * 47 + y * 11) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1], compression="tiff_adobe_deflate")

with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    assert reopened.mode == "RGB", reopened.mode
    assert reopened.size == size, reopened.size
    print("tiff", reopened.mode, reopened.size)
PY
