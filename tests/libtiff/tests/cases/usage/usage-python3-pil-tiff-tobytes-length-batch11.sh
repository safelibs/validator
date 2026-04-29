#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tobytes-length-batch11
# @title: Pillow TIFF tobytes length
# @description: Reads TIFF pixel bytes through Pillow and checks the expected byte length.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tiff-tobytes-length-batch11"
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

im = reopen(source)
data = im.tobytes()
assert len(data) == im.size[0] * im.size[1] * 3
print(len(data))
PYCASE
