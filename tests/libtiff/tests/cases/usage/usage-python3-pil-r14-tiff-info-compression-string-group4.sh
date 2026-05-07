#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-info-compression-string-group4
# @title: PIL bilevel TIFF saved with group4 exposes info["compression"] string "group4"
# @description: Saves a mode "1" bilevel TIFF with Pillow compression='group4' and verifies image.info["compression"] equals "group4" (PIL's string id for the CCITT T.6 codec, numeric Compression tag value 4) on reopen, asserting libtiff's Group 4 fax codec is announced through the Pillow info dict.
# @timeout: 60
# @tags: usage, tiff, python, compression, group4
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/g4.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('1', (32, 32), 1).save(sys.argv[1], 'TIFF', compression='group4')

with Image.open(sys.argv[1]) as im:
    im.load()
    comp = im.info.get('compression')
    assert comp == 'group4', ('info[compression]', comp)
    assert im.mode == '1', ('mode', im.mode)
PY
