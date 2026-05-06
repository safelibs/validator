#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-tiff-1bit-bilevel
# @title: Pillow 1-bit bilevel TIFF roundtrip
# @description: Saves a Pillow mode 1 (bilevel) image as TIFF and verifies the reopened TIFF reports mode 1 with the expected pixel pattern.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/bw.tiff" <<'PY'
import sys
from PIL import Image
img = Image.new("1", (8, 8), 0)
# Set a checkerboard.
for y in range(8):
    for x in range(8):
        if (x + y) % 2 == 0:
            img.putpixel((x, y), 1)
img.save(sys.argv[1], "TIFF")

with Image.open(sys.argv[1]) as ro:
    ro.load()
    assert ro.mode == "1", ro.mode
    got = list(ro.getdata())
    expected = [255 if (x + y) % 2 == 0 else 0 for y in range(8) for x in range(8)]
    assert got == expected, (got[:8], expected[:8])
PY
