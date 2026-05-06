#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-tiff-rgba-roundtrip
# @title: Pillow RGBA TIFF roundtrip preserves alpha
# @description: Saves an RGBA TIFF with a known alpha channel and verifies the reopened TIFF returns the original alpha values pixel-for-pixel.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/rgba.tiff" <<'PY'
import sys
from PIL import Image
src = Image.new("RGBA", (4, 4))
expected = []
for y in range(4):
    for x in range(4):
        c = (x * 30, y * 40, (x + y) * 20, 50 + (x * y) * 10)
        src.putpixel((x, y), c)
        expected.append(c)
src.save(sys.argv[1], "TIFF")

with Image.open(sys.argv[1]) as ro:
    ro.load()
    assert ro.mode == "RGBA", ro.mode
    got = list(ro.getdata())
    assert got == expected, list(zip(got, expected))
PY
