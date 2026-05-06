#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-tiff-l-mode-roundtrip
# @title: Pillow L-mode 8-bit grayscale TIFF roundtrip
# @description: Saves an 8-bit grayscale TIFF via Pillow and verifies all pixel values survive the roundtrip exactly.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/gray.tiff" <<'PY'
import sys
from PIL import Image
img = Image.new("L", (16, 8))
expected = []
for y in range(8):
    for x in range(16):
        v = (x * 16 + y * 4) & 0xff
        img.putpixel((x, y), v)
        expected.append(v)
img.save(sys.argv[1], "TIFF")

with Image.open(sys.argv[1]) as ro:
    ro.load()
    assert ro.mode == "L", ro.mode
    assert list(ro.getdata()) == expected
PY
