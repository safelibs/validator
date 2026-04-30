#!/usr/bin/env bash
# @testcase: usage-python3-pil-image-copy-paste-jpeg
# @title: Pillow Image.copy then paste subimage on JPEG
# @description: Opens a JPEG, copies it, pastes a smaller solid color subimage into the copy at a known offset, saves to JPEG, and verifies the pasted region matches the patch color while the untouched region matches the original background.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-image-copy-paste-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'pasted.jpg'

Image.new('RGB', (32, 32), (128, 128, 128)).save(source, 'JPEG', quality=100, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.size == (32, 32)
    canvas = im.copy()
    patch = Image.new('RGB', (8, 8), (250, 30, 30))
    canvas.paste(patch, (4, 4))
    canvas.save(output, 'JPEG', quality=100, subsampling=0)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.size == (32, 32)
    # Inside the pasted patch the center pixel should be near the patch color.
    inside = im.getpixel((7, 7))
    assert inside[0] > 200 and inside[1] < 70 and inside[2] < 70, inside
    # Outside the patch area the canvas should still show the original gray background.
    outside = im.getpixel((20, 20))
    assert abs(outside[0] - 128) < 12 and abs(outside[1] - 128) < 12 and abs(outside[2] - 128) < 12, outside
    print('copy-paste', inside, outside)

assert output.read_bytes()[:3] == b'\xff\xd8\xff'
PYCASE

file "$tmpdir/pasted.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
