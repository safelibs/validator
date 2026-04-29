#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-bytesio-open-batch11
# @title: Pillow WebP BytesIO open
# @description: Saves WebP data to memory and reopens it from a BytesIO object.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-bytesio-open-batch11"
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

buf = BytesIO()
base.save(buf, 'WEBP', lossless=True)
buf.seek(0)
im = Image.open(buf)
im.load()
assert im.format == 'WEBP' and im.size == base.size
print(im.format)
PYCASE
