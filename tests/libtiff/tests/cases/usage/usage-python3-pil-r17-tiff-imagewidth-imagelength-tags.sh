#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-tiff-imagewidth-imagelength-tags
# @title: Pillow TIFF ImageWidth (256) and ImageLength (257) tags match the image size on read
# @description: Saves a 17x13 RGB TIFF with Pillow, reopens it, and asserts tag_v2[256] equals 17 and tag_v2[257] equals 13, confirming libtiff round-trips ImageWidth/ImageLength tags consistent with Pillow's reported size.
# @timeout: 60
# @tags: usage, tiff, python, dimensions, tag, r17
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/dims.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (17, 13), (5, 6, 7)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    w = im.tag_v2.get(256)
    h = im.tag_v2.get(257)
    assert int(w) == 17, ('width', w)
    assert int(h) == 13, ('length', h)
    assert im.size == (17, 13), ('size', im.size)
print('ok 17x13')
PY
