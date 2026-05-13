#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-tiff-datetime-tag-306-roundtrip
# @title: PIL TIFF DateTime tag 306 written via tiffinfo dict survives a save+reopen
# @description: Saves a small RGB TIFF with tag_v2 DateTime 306 supplied via the tiffinfo kwarg, reopens the file with Pillow, and asserts tag_v2[306] equals the original ASCII timestamp, exercising libtiff's ASCII DateTime tag write/read.
# @timeout: 60
# @tags: usage, tiff, python, tag, datetime
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/dt306.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image, TiffImagePlugin

stamp = '2026:05:13 09:08:07'
ifd = TiffImagePlugin.ImageFileDirectory_v2()
ifd[306] = stamp

Image.new('RGB', (4, 4), (7, 7, 7)).save(
    sys.argv[1], 'TIFF', tiffinfo=ifd,
)

with Image.open(sys.argv[1]) as im:
    im.load()
    dt = im.tag_v2.get(306)
    assert dt == stamp, ('tag306', dt)
PY
