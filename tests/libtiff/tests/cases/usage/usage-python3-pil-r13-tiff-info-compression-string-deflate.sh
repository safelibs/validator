#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-tiff-info-compression-string-deflate
# @title: PIL TIFF saved with tiff_adobe_deflate reports info["compression"] as a deflate variant
# @description: Saves an RGB TIFF with Pillow compression='tiff_adobe_deflate' and verifies image.info["compression"] is one of the documented deflate string ids ("tiff_adobe_deflate" or "tiff_deflate"), exercising the libtiff zip codec discovery path through the Pillow info dictionary rather than via the numeric Compression tag.
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
Image.new('RGB', (24, 16), (200, 30, 30)).save(sys.argv[1], 'TIFF', compression='tiff_adobe_deflate')

with Image.open(sys.argv[1]) as im:
    im.load()
    comp = im.info.get('compression')
    assert comp in ('tiff_adobe_deflate', 'tiff_deflate'), ('info[compression]', comp)
PY
