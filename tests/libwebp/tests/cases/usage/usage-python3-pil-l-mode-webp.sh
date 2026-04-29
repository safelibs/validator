#!/usr/bin/env bash
# @testcase: usage-python3-pil-l-mode-webp
# @title: python PIL L mode WebP
# @description: Exercises python pil l mode webp through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-l-mode-webp"
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

out = Image.new('L', (4, 3), 83)
out.save(tmpdir / 'out.webp', 'WEBP', lossless=True)
with Image.open(tmpdir / 'out.webp') as im:
    pixel = im.getpixel((0, 0))
    assert im.size == (4, 3)
    if isinstance(pixel, tuple):
        assert len(set(pixel[:3])) == 1
    print('l-mode', im.mode)
PY
