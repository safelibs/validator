#!/usr/bin/env bash
# @testcase: usage-python3-pil-tobytes-raw-jpeg
# @title: Pillow tobytes raw on JPEG
# @description: Loads a JPEG with Pillow and verifies Image.tobytes("raw") returns width*height*channels bytes matching the image mode.
# @timeout: 120
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tobytes-raw-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.jpg'
Image.new('RGB', (16, 16), (128, 128, 128)).save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (16, 16)
    raw = im.tobytes('raw')
    expected = 16 * 16 * 3
    assert len(raw) == expected, (len(raw), expected)
    assert isinstance(raw, (bytes, bytearray))
    print('tobytes', len(raw), im.mode, im.size)
PYCASE
