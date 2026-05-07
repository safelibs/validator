#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-lzw-compression-tag-5
# @title: PIL TIFF saved with tiff_lzw sets Compression tag 5 and tiffinfo reports LZW
# @description: Saves an RGB TIFF with Pillow compression='tiff_lzw' and verifies tag_v2[259] == 5 (LZW) and tiffinfo reports "Compression Scheme: LZW", asserting the libtiff LZW codec path from Pillow.
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
Image.new('RGB', (32, 24), (10, 200, 50)).save(sys.argv[1], 'TIFF', compression='tiff_lzw')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.tag_v2.get(259) == 5, ('Compression', im.tag_v2.get(259))
PY

tiffinfo "$path" | grep -E 'Compression Scheme: LZW' >/dev/null
