#!/usr/bin/env bash
# @testcase: usage-python3-pil-imageops-crop-border-jpeg
# @title: Pillow ImageOps.crop border removal on JPEG
# @description: Opens a JPEG, calls ImageOps.crop with a uniform border value to remove pixels from each edge, saves to JPEG, and verifies the resulting size shrinks by twice the border in each axis.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imageops-crop-border-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageOps
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'cropped.jpg'

Image.new('RGB', (32, 24), (128, 128, 128)).save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.size == (32, 24)
    cropped = ImageOps.crop(im, border=4)
    # crop with border=4 removes 4px from each side -> 32-8 by 24-8
    assert cropped.size == (24, 16), cropped.size
    cropped.save(output, 'JPEG', quality=95, subsampling=0)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.size == (24, 16), im.size
    assert im.mode == 'RGB'
    print('crop-border', im.size)

assert output.read_bytes()[:3] == b'\xff\xd8\xff'
PYCASE

file "$tmpdir/cropped.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
