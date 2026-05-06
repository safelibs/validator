#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-pal2rgb-palette-to-rgb
# @title: pal2rgb expands a Pillow palette TIFF into RGB samples
# @description: Saves a P-mode TIFF with Pillow, runs pal2rgb to convert it to RGB, and verifies the result reopens with mode RGB, SamplesPerPixel=3, and PhotometricInterpretation=2 (RGB).
# @timeout: 180
# @tags: usage, tiff, python, pal2rgb
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/palette.tiff"
dst="$tmpdir/rgb.tiff"

python3 - "$src" <<'PY'
import sys
from PIL import Image
img = Image.new("P", (24, 16))
palette = []
for i in range(256):
    palette.extend(((i * 2) % 256, (i * 3) % 256, (i * 5) % 256))
img.putpalette(palette)
img.putdata([(x + y * 5) % 256 for y in range(16) for x in range(24)])
img.save(sys.argv[1], "TIFF")
PY

validator_require_file "$src"
pal2rgb "$src" "$dst"
validator_require_file "$dst"

python3 - "$dst" <<'PY'
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == "RGB", im.mode
    assert im.size == (24, 16), im.size
    spp = im.tag_v2.get(277)
    photo = im.tag_v2.get(262)
    assert spp == 3, ("SamplesPerPixel", spp)
    assert photo == 2, ("PhotometricInterpretation", photo)
PY
