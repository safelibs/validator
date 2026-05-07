#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-tiff-rgba-getpixel-corner-roundtrip
# @title: PIL RGBA TIFF returns the exact corner pixel via getpixel after reopen
# @description: Writes a Pillow mode "RGBA" TIFF filled with (12, 34, 56, 78) and verifies on reopen that mode == "RGBA" and getpixel((0, 0)) returns the same 4-tuple unchanged, asserting libtiff carries all four 8-bit RGBA samples without channel reordering or alpha drop.
# @timeout: 60
# @tags: usage, tiff, python, rgba, getpixel
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/rgba-corner.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGBA', (8, 8), (12, 34, 56, 78)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'RGBA', ('mode', im.mode)
    px = im.getpixel((0, 0))
    assert px == (12, 34, 56, 78), ('pixel', px)
PY
