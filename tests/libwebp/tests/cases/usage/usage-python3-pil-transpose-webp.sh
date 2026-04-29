#!/usr/bin/env bash
# @testcase: usage-python3-pil-transpose-webp
# @title: python PIL transpose WebP
# @description: Exercises python pil transpose webp through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-transpose-webp"
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
    out = im.transpose(Image.Transpose.TRANSPOSE)
    out.save(tmpdir / 'out.webp', 'WEBP')
with Image.open(tmpdir / 'out.webp') as im:
    assert im.size == (3, 4)
    print('transpose', im.size)
PY
