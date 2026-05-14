#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-tiff-artist-tag-roundtrip
# @title: Pillow TIFF Artist tag 315 round-trips via tag_v2
# @description: Writes a TIFF with the Artist tag (315) set to a fixed string via the tiffinfo kwarg, reopens with Pillow, and asserts tag_v2[315] equals the original string byte-for-byte, confirming libtiff's ASCII tag round-trip via Pillow.
# @timeout: 60
# @tags: usage, tiff, python, artist, tag, r17
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/artist.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

ifd = ImageFileDirectory_v2()
ifd[315] = 'r17-pil-artist'
Image.new('RGB', (4, 4)).save(sys.argv[1], 'TIFF', tiffinfo=ifd)

with Image.open(sys.argv[1]) as im:
    im.load()
    artist = im.tag_v2.get(315)
    assert artist == 'r17-pil-artist', ('artist', artist)
print('ok artist roundtrip')
PY
