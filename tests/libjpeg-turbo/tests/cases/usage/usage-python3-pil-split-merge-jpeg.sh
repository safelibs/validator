#!/usr/bin/env bash
# @testcase: usage-python3-pil-split-merge-jpeg
# @title: python PIL split merge JPEG
# @description: Exercises python pil split merge jpeg through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-split-merge-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageFilter, ImageOps
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.jpg'
Image.new('RGB', (4, 3), (120, 40, 200)).save(source, 'JPEG')

with Image.open(source) as im:
    out = Image.merge('RGB', im.split())
    out.save(tmpdir / 'out.jpg', 'JPEG')
with Image.open(tmpdir / 'out.jpg') as im:
    assert im.mode == 'RGB'
    print('merge', im.mode)
PY
