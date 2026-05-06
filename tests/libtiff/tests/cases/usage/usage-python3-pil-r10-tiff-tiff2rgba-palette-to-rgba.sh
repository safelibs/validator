#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-tiff2rgba-palette-to-rgba
# @title: tiff2rgba expands a Pillow palette TIFF into RGBA samples
# @description: Saves a P-mode palette TIFF with Pillow, runs tiff2rgba to convert it, and verifies the result reopens as RGBA with SamplesPerPixel=4 and the original geometry preserved.
# @timeout: 180
# @tags: usage, tiff, python, tiff2rgba
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/palette.tiff"
dst="$tmpdir/rgba.tiff"

python3 - "$src" <<'PY'
import sys
from PIL import Image
img = Image.new("P", (16, 12))
palette = []
for i in range(256):
    palette.extend(((i * 3) % 256, (i * 5) % 256, (i * 7) % 256))
img.putpalette(palette)
img.putdata([(x * 7 + y * 3) % 256 for y in range(12) for x in range(16)])
img.save(sys.argv[1], "TIFF")
PY

validator_require_file "$src"
tiff2rgba "$src" "$dst"
validator_require_file "$dst"

python3 - "$dst" <<'PY'
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == "RGBA", im.mode
    assert im.size == (16, 12), im.size
    spp = im.tag_v2.get(277)
    assert spp == 4, ("SamplesPerPixel", spp)
PY
