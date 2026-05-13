#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-tiff-i16-roundtrip-size-and-mode
# @title: PIL I;16 TIFF preserves mode I;16 and 10x7 dimensions across save and reopen
# @description: Saves a 10x7 I;16 image with constant value 12345 as a TIFF, reopens with Pillow, asserts the reopened mode is exactly "I;16", asserts the reopened size is (10, 7), and asserts every sampled pixel along the diagonal equals the original constant.
# @timeout: 60
# @tags: usage, tiff, python, sixteen-bit
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/i16-10x7.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

Image.new('I;16', (10, 7), 12345).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'I;16', ('mode', im.mode)
    assert im.size == (10, 7), ('size', im.size)
    for x in range(min(im.size)):
        assert im.getpixel((x, x)) == 12345, ('diag', x, im.getpixel((x, x)))
PY
