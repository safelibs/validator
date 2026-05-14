#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-tiff-rowsperstrip-tag-positive
# @title: Pillow RGB TIFF reports RowsPerStrip tag 278 as a positive integer
# @description: Saves a 32x32 RGB TIFF, reopens it with Pillow, asserts tag_v2[278] (RowsPerStrip) is castable to a positive integer no greater than the image height (32), confirming libtiff records strip geometry consistent with image dimensions.
# @timeout: 60
# @tags: usage, tiff, python, rowsperstrip, r17
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/rps.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (32, 32), (10, 20, 30)).save(sys.argv[1], 'TIFF', compression='raw')

with Image.open(sys.argv[1]) as im:
    im.load()
    rps = im.tag_v2.get(278)
    iv = int(rps)
    assert iv > 0, ('rps', rps, iv)
    assert iv <= 32, ('rps too big', iv)
print('ok rps=%d' % iv)
PY
