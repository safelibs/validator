#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-mode-rgba-alpha-channel-roundtrip
# @title: PIL TIFF mode "RGBA" round-trips and exposes a 4th alpha band on reopen
# @description: Saves a mode "RGBA" TIFF with a non-trivial alpha channel and verifies on reopen that mode == "RGBA", split() produces 4 bands, and the alpha band's getextrema() returns the expected (min,max) tuple, asserting libtiff round-trips the alpha sample through Pillow.
# @timeout: 60
# @tags: usage, tiff, python, rgba, alpha
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/rgba.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
img = Image.new('RGBA', (8, 8), (10, 20, 30, 128))
img.save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'RGBA', ('mode', im.mode)
    bands = im.split()
    assert len(bands) == 4, ('band count', len(bands))
    alpha = bands[3]
    extrema = alpha.getextrema()
    assert extrema == (128, 128), ('alpha extrema', extrema)
PY
