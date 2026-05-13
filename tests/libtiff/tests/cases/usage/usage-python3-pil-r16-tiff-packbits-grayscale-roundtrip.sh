#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-tiff-packbits-grayscale-roundtrip
# @title: PIL L-mode TIFF saved with packbits compression preserves dimensions and pixels
# @description: Creates a 12x12 grayscale (L) image with a deterministic ramp, saves as TIFF with compression='packbits', reopens with Pillow, asserts mode L and size 12x12, asserts the pixel at (0,0) and (11,11) match the original values, and asserts info['compression'] is one of the accepted packbits identifiers (string 'packbits' or int 32773).
# @timeout: 60
# @tags: usage, tiff, python, packbits, grayscale
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/l-packbits.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

src = Image.new('L', (12, 12))
src.putdata([(x * 16 + y) & 0xff for y in range(12) for x in range(12)])
src.save(sys.argv[1], 'TIFF', compression='packbits')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'L', ('mode', im.mode)
    assert im.size == (12, 12), ('size', im.size)
    assert im.getpixel((0, 0)) == src.getpixel((0, 0))
    assert im.getpixel((11, 11)) == src.getpixel((11, 11))
    comp = im.info.get('compression')
    assert comp in ('packbits', 32773), ('compression', comp)
PY
