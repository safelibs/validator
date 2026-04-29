#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-dpi-info-batch11
# @title: Pillow TIFF DPI info
# @description: Saves a TIFF with DPI information through Pillow and checks it after reopening.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tiff-dpi-info-batch11"
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

out = tmpdir / 'dpi.tiff'
base.save(out, 'TIFF', dpi=(300, 300))
im = reopen(out)
assert tuple(round(v) for v in im.info.get('dpi', (0, 0))) == (300, 300)
print(im.info.get('dpi'))
PYCASE
