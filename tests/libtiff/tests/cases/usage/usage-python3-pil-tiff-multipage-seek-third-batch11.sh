#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-multipage-seek-third-batch11
# @title: Pillow TIFF multipage seek third
# @description: Writes a three-page TIFF and seeks to the third frame with Pillow.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tiff-multipage-seek-third-batch11"
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

out = tmpdir / 'multi.tiff'
frames = [Image.new('L', (2, 2), value) for value in (10, 20, 30)]
frames[0].save(out, save_all=True, append_images=frames[1:])
im = Image.open(out)
im.seek(2)
assert im.getpixel((0, 0)) == 30
print(im.n_frames)
PYCASE
