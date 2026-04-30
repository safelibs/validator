#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-deflate-info-tag
# @title: Pillow TIFF deflate info tag
# @description: Saves a TIFF with compression=tiff_deflate and verifies the reopened info compression and Compression tag value.
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

path = sys.argv[1]
size = (6, 5)
pixels = [
    ((x * 11 + y * 19) % 256, (x * 23 + y * 7) % 256, (x * 5 + y * 31) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(path, compression="tiff_deflate")

with Image.open(path) as reopened:
    reopened.load()
    compression = reopened.info.get("compression")
    assert compression in ("tiff_deflate", "tiff_adobe_deflate"), compression
    tag = reopened.tag_v2.get(259)
    assert tag in (8, 32946), tag
    assert reopened.size == size, reopened.size
    assert reopened.mode == "RGB", reopened.mode
    print("deflate", compression, tag)
PY
