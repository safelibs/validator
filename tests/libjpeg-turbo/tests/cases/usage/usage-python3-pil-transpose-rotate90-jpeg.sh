#!/usr/bin/env bash
# @testcase: usage-python3-pil-transpose-rotate90-jpeg
# @title: Pillow transpose ROTATE_90 on JPEG
# @description: Rotates a JPEG 90 degrees with Image.transpose(Image.ROTATE_90), saves, and verifies dimension swap and JPEG roundtrip.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-transpose-rotate90-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'out.jpg'

base = Image.new('RGB', (6, 4), (40, 80, 200))
base.save(source, 'JPEG', quality=95)

rotate = getattr(Image, 'Transpose', Image).ROTATE_90

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.size == (6, 4)
    rotated = im.transpose(rotate)
    assert rotated.size == (4, 6), rotated.size
    rotated.save(output, 'JPEG', quality=95)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (4, 6), im.size
    print('rotated', im.size, im.format)
PYCASE

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
