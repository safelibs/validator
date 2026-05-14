#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-tiff-copyright-tag-roundtrip
# @title: Pillow TIFF Copyright tag 33432 round-trips via tag_v2
# @description: Writes a TIFF with the Copyright tag (33432) set to a fixed string via the tiffinfo kwarg, reopens with Pillow, and asserts tag_v2[33432] equals the original string byte-for-byte, confirming libtiff's ASCII Copyright tag round-trip.
# @timeout: 60
# @tags: usage, tiff, python, copyright, tag, r17
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/copyright.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

ifd = ImageFileDirectory_v2()
ifd[33432] = 'r17 (c) validator'
Image.new('RGB', (4, 4)).save(sys.argv[1], 'TIFF', tiffinfo=ifd)

with Image.open(sys.argv[1]) as im:
    im.load()
    cr = im.tag_v2.get(33432)
    assert cr == 'r17 (c) validator', ('copyright', cr)
print('ok copyright roundtrip')
PY
