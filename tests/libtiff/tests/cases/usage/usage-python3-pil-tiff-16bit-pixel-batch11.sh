#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-16bit-pixel-batch11
# @title: Pillow TIFF 16-bit pixel
# @description: Saves and reopens a 16-bit TIFF pixel value through Pillow.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tiff-16bit-pixel-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageOps, ImageSequence
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
base = Image.new('RGB', (5, 4), (20, 40, 80))
source = tmpdir / 'input.tiff'
base.save(source, 'TIFF')

def reopen(path):
    im = Image.open(path)
    im.load()
    return im

out = tmpdir / 'sixteen.tiff'
img = Image.new('I;16', (2, 1))
img.putdata([1, 1024])
img.save(out, 'TIFF')
im = reopen(out)
assert im.getpixel((1, 0)) == 1024
print(im.mode, im.getpixel((1, 0)))
PYCASE
