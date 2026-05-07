#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-tiff-mode-i16-extrema-roundtrip
# @title: PIL I;16 TIFF reports the expected extrema for a flat 32000 image
# @description: Writes a Pillow I;16 grayscale TIFF whose every pixel is 32000 and verifies the reopened image's mode is "I;16" and getextrema() returns (32000, 32000), asserting libtiff carries 16-bit grayscale samples and Pillow surfaces both extrema accurately for a uniform image.
# @timeout: 60
# @tags: usage, tiff, python, sixteen-bit, extrema
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/i16-flat.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('I;16', (8, 8), 32000).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'I;16', ('mode', im.mode)
    extrema = im.getextrema()
    assert extrema == (32000, 32000), ('extrema', extrema)
PY
