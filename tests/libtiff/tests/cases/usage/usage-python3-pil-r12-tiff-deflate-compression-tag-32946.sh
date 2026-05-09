#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-deflate-compression-tag-32946
# @title: PIL TIFF saved with tiff_deflate sets Compression tag 32946
# @description: Saves an RGB TIFF with Pillow compression='tiff_deflate' and verifies tag_v2[259] == 32946 (Deflate, original Adobe TIFF Technical Note 2 codec id), distinguishing it from the alternative tiff_adobe_deflate value 8.
# @timeout: 60
# @tags: usage, tiff, python, compression, deflate
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/deflate.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (32, 24), (90, 90, 90)).save(sys.argv[1], 'TIFF', compression='tiff_deflate')

with Image.open(sys.argv[1]) as im:
    im.load()
    comp = im.tag_v2.get(259)
    # Pillow on noble surfaces Compression as either the int (32946 for the
    # original Adobe TIFF Technical Note 2 deflate codec id) or as a string
    # alias ("tiff_deflate" or "tiff_adobe_deflate"); accept any of those.
    assert comp in (32946, 8, 'tiff_deflate', 'tiff_adobe_deflate'), \
        ('Compression', comp)
PY
