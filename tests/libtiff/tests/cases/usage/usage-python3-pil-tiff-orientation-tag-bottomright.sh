#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-orientation-tag-bottomright
# @title: Pillow TIFF explicit Orientation tag value 3 round-trip
# @description: Saves a TIFF with the Orientation tag (274) set to 3 (rotated 180 / bottom-right) via ImageFileDirectory_v2 and verifies the tag value reloads as 3 without altering the underlying pixel buffer.
# @timeout: 180
# @tags: usage, image, python, orientation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/oriented.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

size = (8, 6)
pixels = bytes(
    component
    for y in range(size[1])
    for x in range(size[0])
    for component in ((x * 31) & 0xFF, (y * 41) & 0xFF, ((x + y) * 17) & 0xFF)
)
image = Image.frombytes("RGB", size, pixels)
ifd = ImageFileDirectory_v2()
ifd[274] = 3
image.save(sys.argv[1], tiffinfo=ifd)

with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    orient = reopened.tag_v2.get(274)
    orient_val = orient[0] if hasattr(orient, "__len__") else orient
    assert orient_val == 3, orient
    # Pillow does not auto-transpose on load; raw bytes should match.
    assert reopened.tobytes() == pixels, "raw pixel buffer mutated"
    assert reopened.size == size, reopened.size
    print("orientation", orient_val)
PY
