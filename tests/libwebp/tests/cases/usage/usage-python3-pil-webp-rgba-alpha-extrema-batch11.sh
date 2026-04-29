#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-rgba-alpha-extrema-batch11
# @title: Pillow WebP RGBA alpha extrema
# @description: Saves RGBA WebP data and checks alpha extrema after reopening.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-rgba-alpha-extrema-batch11"
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

out = tmpdir / 'alpha.webp'
rgba = Image.new('RGBA', (2, 1))
rgba.putdata([(1, 2, 3, 0), (4, 5, 6, 255)])
rgba.save(out, 'WEBP', lossless=True)
im = reopen(out).convert('RGBA')
assert im.getchannel('A').getextrema() == (0, 255)
print(im.getchannel('A').getextrema())
PYCASE
