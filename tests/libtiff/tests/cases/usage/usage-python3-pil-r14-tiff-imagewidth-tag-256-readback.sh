#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-imagewidth-tag-256-readback
# @title: PIL TIFF tag_v2[256] (ImageWidth) reads back the saved image width
# @description: Saves a 37x21 RGB TIFF and verifies that tag_v2.get(256) (ImageWidth) on reopen equals 37 (matching image.size[0]), asserting libtiff records the canonical ImageWidth tag and Pillow surfaces it as an integer through the v2 IFD.
# @timeout: 60
# @tags: usage, tiff, python, tags, imagewidth
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/width.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (37, 21), (10, 20, 30)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    width_tag = im.tag_v2.get(256)
    assert width_tag == 37, ('ImageWidth tag(256)', width_tag)
    assert im.size == (37, 21), ('size', im.size)
PY
