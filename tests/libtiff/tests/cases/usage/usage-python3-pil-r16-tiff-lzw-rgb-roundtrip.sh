#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-tiff-lzw-rgb-roundtrip
# @title: PIL RGB TIFF saved with tiff_lzw compression roundtrips pixel data exactly
# @description: Builds a 16x16 RGB image with a deterministic gradient, saves it as TIFF with compression='tiff_lzw', reopens with Pillow, asserts the reopened image is RGB sized 16x16, and asserts a sampled corner pixel matches the original byte-for-byte.
# @timeout: 60
# @tags: usage, tiff, python, lzw, rgb
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/rgb-lzw.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

src = Image.new('RGB', (16, 16))
src.putdata([((x * 8) & 0xff, (y * 8) & 0xff, ((x + y) * 4) & 0xff)
             for y in range(16) for x in range(16)])
src.save(sys.argv[1], 'TIFF', compression='tiff_lzw')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'RGB', ('mode', im.mode)
    assert im.size == (16, 16), ('size', im.size)
    assert im.getpixel((0, 0)) == src.getpixel((0, 0)), ('00', im.getpixel((0, 0)))
    assert im.getpixel((15, 15)) == src.getpixel((15, 15)), ('15', im.getpixel((15, 15)))
PY
