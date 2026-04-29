#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-optimize-save-batch11
# @title: Pillow optimized JPEG save
# @description: Saves an optimized JPEG through Pillow and verifies it reopens.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-jpeg-optimize-save-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageOps
from io import BytesIO
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
base = Image.new('RGB', (8, 6))
base.putdata([(x * 30 % 256, y * 40 % 256, (x + y) * 20 % 256) for y in range(6) for x in range(8)])
source = tmpdir / 'input.jpg'
base.save(source, 'JPEG', quality=95, subsampling=0)

def reopen(path):
    im = Image.open(path)
    im.load()
    return im

out = tmpdir / 'opt.jpg'
ImageOps.autocontrast(base).save(out, 'JPEG', optimize=True, quality=85)
im = reopen(out)
assert im.format == 'JPEG'
assert im.size == base.size
print(out.stat().st_size)
PYCASE
