#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-tiff-transpose-flip-left-right-mirrors-pixel
# @title: Pillow Image.transpose FLIP_LEFT_RIGHT on a TIFF reload mirrors a specific column
# @description: Saves a 6x3 mode-L TIFF, places a unique value at column 0 row 0, reopens, calls .transpose(Image.FLIP_LEFT_RIGHT), and asserts the resulting image getpixel((5, 0)) equals the source's column-0 row-0 value (mirror moves column 0 to column 5 in width=6), confirming libtiff-decoded pixels feed the PIL transpose correctly.
# @timeout: 60
# @tags: usage, tiff, python, transpose, mirror, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/mir.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

im = Image.new('L', (6, 3), 0)
im.putpixel((0, 0), 177)
im.save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as r:
    r.load()
    flipped = r.transpose(Image.FLIP_LEFT_RIGHT)
    assert flipped.size == (6, 3), flipped.size
    assert flipped.getpixel((5, 0)) == 177, flipped.getpixel((5, 0))
    print('ok mirror pixel=%d' % flipped.getpixel((5, 0)))
PY
