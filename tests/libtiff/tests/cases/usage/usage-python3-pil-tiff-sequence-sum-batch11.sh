#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-sequence-sum-batch11
# @title: Pillow TIFF sequence sum
# @description: Iterates multi-page TIFF frames with Pillow and sums their pixel values.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tiff-sequence-sum-batch11"
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

out = tmpdir / 'seq.tiff'
frames = [Image.new('L', (1, 1), value) for value in (4, 5, 6)]
frames[0].save(out, save_all=True, append_images=frames[1:])
im = Image.open(out)
total = sum(frame.copy().getpixel((0, 0)) for frame in ImageSequence.Iterator(im))
assert total == 15
print(total)
PYCASE
