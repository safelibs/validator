#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-palette-convert-batch11
# @title: Pillow WebP palette convert
# @description: Converts an image through a palette and saves the result as WebP.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-palette-convert-batch11"
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

out = tmpdir / 'palette.webp'
pal = base.convert('P', palette=Image.Palette.ADAPTIVE, colors=4).convert('RGB')
pal.save(out, 'WEBP', lossless=True)
im = reopen(out)
assert im.mode == 'RGB' and im.size == base.size
print(im.mode)
PYCASE
