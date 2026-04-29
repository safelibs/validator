#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-animated-seek-second-batch11
# @title: Pillow WebP animated seek second
# @description: Seeks to the second frame of an animated WebP through Pillow.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-animated-seek-second-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from io import BytesIO
from PIL import Image, ImageSequence, ImageOps, features
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
base = Image.new('RGB', (5, 4), (20, 80, 160))

def reopen(path):
    im = Image.open(path)
    im.load()
    return im

out = tmpdir / 'anim.webp'
frames = [Image.new('RGB', (2, 2), color) for color in ((10, 20, 30), (40, 50, 60))]
frames[0].save(out, 'WEBP', save_all=True, append_images=frames[1:], duration=50, loop=0, lossless=True)
im = Image.open(out)
im.seek(1)
assert im.getpixel((0, 0)) == (40, 50, 60)
print(im.tell())
PYCASE
