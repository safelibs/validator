#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-tiff-software-tag-roundtrip
# @title: Pillow TIFF Software tag 305 round-trips through tag_v2 unchanged
# @description: Writes an RGB TIFF with the Software tag (305) set to a fixed ASCII identifier via a TiffImagePlugin.ImageFileDirectory_v2, reopens with Pillow, and asserts tag_v2[305] equals the original string byte-for-byte, confirming libtiff persists the Software ASCII tag through a save-and-reload cycle.
# @timeout: 60
# @tags: usage, tiff, python, software, tag, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/software.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

ifd = ImageFileDirectory_v2()
ifd[305] = 'r18-pil-software-tag'
Image.new('RGB', (5, 5)).save(sys.argv[1], 'TIFF', tiffinfo=ifd)

with Image.open(sys.argv[1]) as im:
    im.load()
    sw = im.tag_v2.get(305)
    assert sw == 'r18-pil-software-tag', ('software', sw)
print('ok software roundtrip')
PY
