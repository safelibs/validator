#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-tiff-adobe-deflate-compression-roundtrip
# @title: Pillow TIFF with compression="tiff_adobe_deflate" round-trips pixel-equal to the original
# @description: Saves a small RGB pattern as a TIFF using compression="tiff_adobe_deflate", reopens it with Pillow, asserts the reopened mode/size match the source, and asserts the decoded bytes are byte-for-byte equal to the original tobytes() result, confirming libtiff Adobe-flavored deflate compression is lossless.
# @timeout: 60
# @tags: usage, tiff, python, compression, adobe-deflate, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/adobe.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
src = Image.new('RGB', (12, 7))
src.putdata([((i * 7) % 256, (i * 11) % 256, (i * 13) % 256) for i in range(12 * 7)])
src.save(sys.argv[1], 'TIFF', compression='tiff_adobe_deflate')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'RGB', ('mode', im.mode)
    assert im.size == (12, 7), ('size', im.size)
    assert im.tobytes() == src.tobytes(), 'pixel mismatch'
print('ok adobe_deflate lossless')
PY
