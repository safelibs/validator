#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-bytesio-open-batch11
# @title: Pillow TIFF BytesIO open
# @description: Saves a TIFF to memory and reopens it from a BytesIO object.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tiff-bytesio-open-batch11"
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

from io import BytesIO
buf = BytesIO()
base.save(buf, 'TIFF')
buf.seek(0)
im = Image.open(buf)
im.load()
assert im.format == 'TIFF' and im.size == base.size
print(im.format)
PYCASE
