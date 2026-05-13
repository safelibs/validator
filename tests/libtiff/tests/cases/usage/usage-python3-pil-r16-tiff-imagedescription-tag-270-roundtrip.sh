#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-tiff-imagedescription-tag-270-roundtrip
# @title: PIL TIFF ImageDescription tag 270 written via description kwarg roundtrips through tag_v2
# @description: Saves a small RGB TIFF with a fixed description=... kwarg, reopens the file with Pillow, and asserts tag_v2[270] equals the original description string, exercising libtiff's ImageDescription tag write/read path through Pillow.
# @timeout: 60
# @tags: usage, tiff, python, tag, imagedescription
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/desc270.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

description = 'r16 imagedescription tag 270 payload'
Image.new('RGB', (6, 6), (12, 34, 56)).save(
    sys.argv[1], 'TIFF', description=description,
)

with Image.open(sys.argv[1]) as im:
    im.load()
    desc_tag = im.tag_v2.get(270)
    assert desc_tag == description, ('tag270', desc_tag)
PY
