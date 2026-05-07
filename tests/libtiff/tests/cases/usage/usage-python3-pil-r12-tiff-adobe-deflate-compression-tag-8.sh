#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-adobe-deflate-compression-tag-8
# @title: PIL TIFF saved with tiff_adobe_deflate sets Compression tag 8 and tiffinfo reports AdobeDeflate
# @description: Saves an RGB TIFF with Pillow compression='tiff_adobe_deflate' and verifies tag_v2[259] == 8 (AdobeDeflate) and tiffinfo reports "Compression Scheme: AdobeDeflate", the modern z-streams TIFF codec id.
# @timeout: 60
# @tags: usage, tiff, python, compression, deflate
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/adobe_deflate.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (32, 24), (5, 60, 200)).save(sys.argv[1], 'TIFF', compression='tiff_adobe_deflate')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.tag_v2.get(259) == 8, ('Compression', im.tag_v2.get(259))
PY

tiffinfo "$path" | grep -E 'Compression Scheme: AdobeDeflate' >/dev/null
