#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-progressive-info-batch11
# @title: Pillow progressive JPEG info
# @description: Saves a progressive JPEG through Pillow and checks progressive metadata.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-jpeg-progressive-info-batch11"
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

out = tmpdir / 'progressive.jpg'
base.save(out, 'JPEG', progressive=True, quality=90)
im = reopen(out)
assert im.info.get('progressive') or im.info.get('progression')
print('progressive')
PYCASE
