#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-info-compression-string-packbits
# @title: PIL TIFF saved with packbits exposes info["compression"] string "packbits"
# @description: Saves an RGB TIFF with Pillow compression='packbits' and verifies that on reopen image.info["compression"] is exactly the literal string "packbits" (PIL's string id, not the numeric tag value 32773), asserting the libtiff PackBits codec is announced through the Pillow info dict.
# @timeout: 60
# @tags: usage, tiff, python, compression, packbits
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/packbits.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (24, 16), (200, 60, 40)).save(sys.argv[1], 'TIFF', compression='packbits')

with Image.open(sys.argv[1]) as im:
    im.load()
    comp = im.info.get('compression')
    assert comp == 'packbits', ('info[compression]', comp)
    assert im.mode == 'RGB', ('mode', im.mode)
    assert im.size == (24, 16), ('size', im.size)
PY
