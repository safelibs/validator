#!/usr/bin/env bash
# @testcase: usage-python3-pil-imageops-scale-jpeg
# @title: Pillow ImageOps.scale on JPEG
# @description: Opens a JPEG, applies ImageOps.scale with a 2.0 factor, saves the result back to JPEG, and verifies the output size doubles in both dimensions.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imageops-scale-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageOps
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'scaled.jpg'

Image.new('RGB', (16, 12), (128, 128, 128)).save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.size == (16, 12)
    scaled = ImageOps.scale(im, 2.0)
    assert scaled.size == (32, 24), scaled.size
    scaled.save(output, 'JPEG', quality=95, subsampling=0)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.size == (32, 24), im.size
    assert im.mode == 'RGB'
    print('scale', im.size)

assert output.read_bytes()[:3] == b'\xff\xd8\xff'
PYCASE

file "$tmpdir/scaled.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
