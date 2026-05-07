#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-info-compression-string-tiff-jpeg
# @title: PIL TIFF saved with jpeg compression exposes info["compression"] as a jpeg id
# @description: Saves an RGB TIFF with Pillow compression='jpeg' and verifies image.info["compression"] is one of the jpeg-family string ids ("jpeg" or "tiff_jpeg") on reopen, asserting libtiff's JPEG-in-TIFF codec is announced through the Pillow info dict rather than via the numeric Compression tag (7).
# @timeout: 60
# @tags: usage, tiff, python, compression, jpeg
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/jpeg.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (32, 32), (180, 90, 30)).save(sys.argv[1], 'TIFF', compression='jpeg')

with Image.open(sys.argv[1]) as im:
    im.load()
    comp = im.info.get('compression')
    assert comp in ('jpeg', 'tiff_jpeg'), ('info[compression]', comp)
    assert im.mode == 'RGB', ('mode', im.mode)
    assert im.size == (32, 32), ('size', im.size)
PY
