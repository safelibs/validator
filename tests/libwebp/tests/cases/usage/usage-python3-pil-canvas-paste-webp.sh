#!/usr/bin/env bash
# @testcase: usage-python3-pil-canvas-paste-webp
# @title: python PIL canvas paste WebP
# @description: Exercises python pil canvas paste webp through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-canvas-paste-webp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageFilter, ImageOps
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.webp'
Image.new('RGB', (4, 3), (120, 40, 200)).save(source, 'WEBP')

with Image.open(source) as im:
    canvas = Image.new('RGB', (8, 6), 'white')
    canvas.paste(im, (2, 1))
    canvas.save(tmpdir / 'out.webp', 'WEBP')
with Image.open(tmpdir / 'out.webp') as im:
    assert im.size == (8, 6)
    print('canvas', im.size)
PY
