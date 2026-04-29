#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-invert-l-mode-batch11
# @title: Pillow TIFF invert L mode
# @description: Inverts grayscale TIFF pixels through Pillow and checks values.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tiff-invert-l-mode-batch11"
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

out = tmpdir / 'invert.tiff'
gray = Image.new('L', (2, 1))
gray.putdata([0, 200])
ImageOps.invert(gray).save(out, 'TIFF')
im = reopen(out)
assert list(im.getdata()) == [255, 55]
print(list(im.getdata()))
PYCASE
