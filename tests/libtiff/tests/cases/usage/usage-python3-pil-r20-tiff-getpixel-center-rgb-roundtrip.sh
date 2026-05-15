#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-tiff-getpixel-center-rgb-roundtrip
# @title: Pillow TIFF RGB image preserves a non-corner pixel through save and reload
# @description: Builds a 7x7 mode-RGB image filled with black, sets pixel (3, 3) to (171, 82, 199), saves as TIFF, reopens, and asserts r.getpixel((3, 3)) equals (171, 82, 199) exactly, confirming libtiff round-trips a single interior RGB triple losslessly.
# @timeout: 60
# @tags: usage, tiff, python, getpixel, rgb, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/center.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

im = Image.new('RGB', (7, 7), (0, 0, 0))
im.putpixel((3, 3), (171, 82, 199))
im.save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as r:
    r.load()
    p = r.getpixel((3, 3))
    assert p == (171, 82, 199), p
    print('ok pixel=%s' % (p,))
PY
