#!/usr/bin/env bash
# @testcase: usage-python3-pil-convert-rgb-to-cmyk-jpeg
# @title: Pillow converts RGB JPEG to CMYK
# @description: Reads an RGB JPEG with Pillow, calls Image.convert("CMYK"), saves the CMYK image as JPEG, and verifies the reopened image reports CMYK mode and four bands.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-convert-rgb-to-cmyk-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'rgb.jpg'
output = tmpdir / 'cmyk.jpg'

# Mid-tone RGB image so the CMYK conversion produces non-degenerate channels.
rgb = Image.new('RGB', (8, 6), (180, 90, 60))
rgb.save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    cmyk = im.convert('CMYK')
    assert cmyk.mode == 'CMYK', cmyk.mode
    assert cmyk.getbands() == ('C', 'M', 'Y', 'K')
    cmyk.save(output, 'JPEG')

with Image.open(output) as im:
    im.load()
    assert im.format == 'JPEG'
    assert im.mode == 'CMYK', im.mode
    assert im.size == (8, 6)
    assert len(im.getbands()) == 4
    print('convert-cmyk', im.mode, im.size, im.getbands())
PYCASE

file "$tmpdir/cmyk.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
