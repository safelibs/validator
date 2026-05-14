#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-tiff-datetime-tag-roundtrip
# @title: Pillow TIFF DateTime tag 306 round-trips a fixed timestamp string
# @description: Writes an RGB TIFF with the DateTime tag (306) set to the canonical libtiff "YYYY:MM:DD HH:MM:SS" timestamp via tiffinfo, reopens with Pillow, and asserts tag_v2[306] equals the original 19-character timestamp string byte-for-byte.
# @timeout: 60
# @tags: usage, tiff, python, datetime, tag, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/datetime.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

stamp = '2024:05:14 12:00:00'
ifd = ImageFileDirectory_v2()
ifd[306] = stamp
Image.new('RGB', (3, 3)).save(sys.argv[1], 'TIFF', tiffinfo=ifd)

with Image.open(sys.argv[1]) as im:
    im.load()
    dt = im.tag_v2.get(306)
    assert dt == stamp, ('datetime', dt)
    assert len(dt) == 19, ('len', len(dt))
print('ok datetime=%s' % dt)
PY
