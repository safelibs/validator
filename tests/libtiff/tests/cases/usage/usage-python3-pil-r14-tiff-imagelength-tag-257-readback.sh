#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-imagelength-tag-257-readback
# @title: PIL TIFF tag_v2[257] (ImageLength) reads back the saved image height
# @description: Saves a 19x43 RGB TIFF and verifies that tag_v2.get(257) (ImageLength) on reopen equals 43 (matching image.size[1]), asserting libtiff records the canonical ImageLength tag and Pillow surfaces it as an integer through the v2 IFD.
# @timeout: 60
# @tags: usage, tiff, python, tags, imagelength
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/length.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (19, 43), (50, 60, 70)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    length_tag = im.tag_v2.get(257)
    assert length_tag == 43, ('ImageLength tag(257)', length_tag)
    assert im.size == (19, 43), ('size', im.size)
PY
