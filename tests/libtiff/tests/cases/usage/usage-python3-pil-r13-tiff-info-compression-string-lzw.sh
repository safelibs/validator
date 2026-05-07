#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-tiff-info-compression-string-lzw
# @title: PIL TIFF saved with tiff_lzw exposes info["compression"] string "tiff_lzw"
# @description: Saves an RGB TIFF with Pillow compression='tiff_lzw' and verifies that on reopen image.info["compression"] is the literal string "tiff_lzw" (PIL's string id, not the numeric tag), asserting the libtiff LZW codec is announced through the Pillow info dict.
# @timeout: 60
# @tags: usage, tiff, python, compression, lzw
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/lzw.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (16, 12), (90, 120, 180)).save(sys.argv[1], 'TIFF', compression='tiff_lzw')

with Image.open(sys.argv[1]) as im:
    im.load()
    comp = im.info.get('compression')
    assert comp == 'tiff_lzw', ('info[compression]', comp)
    assert im.mode == 'RGB', ('mode', im.mode)
    assert im.size == (16, 12), ('size', im.size)
PY
