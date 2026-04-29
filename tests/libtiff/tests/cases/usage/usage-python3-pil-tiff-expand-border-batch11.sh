#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-expand-border-batch11
# @title: Pillow TIFF expand border
# @description: Expands a TIFF canvas with a border through Pillow and verifies the result.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tiff-expand-border-batch11"
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

out = tmpdir / 'border.tiff'
expanded = ImageOps.expand(base, border=2, fill=(1, 2, 3))
expanded.save(out, 'TIFF')
im = reopen(out)
assert im.size == (9, 8)
assert im.getpixel((0, 0)) == (1, 2, 3)
print(im.size)
PYCASE
