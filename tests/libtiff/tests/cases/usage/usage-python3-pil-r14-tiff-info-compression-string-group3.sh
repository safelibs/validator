#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-info-compression-string-group3
# @title: PIL bilevel TIFF saved with group3 exposes info["compression"] string "group3"
# @description: Saves a mode "1" bilevel TIFF with Pillow compression='group3' and verifies image.info["compression"] equals "group3" (PIL's string id for the CCITT T.4 codec, numeric Compression tag value 3) on reopen, asserting libtiff's Group 3 fax codec is announced through the Pillow info dict.
# @timeout: 60
# @tags: usage, tiff, python, compression, group3
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/g3.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('1', (24, 24), 0).save(sys.argv[1], 'TIFF', compression='group3')

with Image.open(sys.argv[1]) as im:
    im.load()
    comp = im.info.get('compression')
    assert comp == 'group3', ('info[compression]', comp)
    assert im.mode == '1', ('mode', im.mode)
PY
