#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-description-tag-batch11
# @title: Pillow TIFF description tag
# @description: Saves a TIFF ImageDescription tag through Pillow and reads it back.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tiff-description-tag-batch11"
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

out = tmpdir / 'desc.tiff'
base.save(out, 'TIFF', tiffinfo={270: 'validator description'})
im = reopen(out)
assert im.tag_v2.get(270) == 'validator description'
print(im.tag_v2.get(270))
PYCASE
