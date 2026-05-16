#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-tiff-save-with-exif-bytes-roundtrip
# @title: Pillow TIFF save round-trip preserves ImageDescription via explicit save kwarg
# @description: Saves a 3x3 RGB TIFF with an explicit description="r21-roundtrip" kwarg, reopens it, and asserts tag 270 (ImageDescription) on tag_v2 equals the supplied string, exercising libtiff string-tag write+read.
# @timeout: 60
# @tags: usage, tiff, python, description, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/desc.tif" <<'PY'
import sys
from PIL import Image

Image.new('RGB', (3, 3), (5, 5, 5)).save(sys.argv[1], 'TIFF', description='r21-roundtrip')

with Image.open(sys.argv[1]) as im:
    tags = im.tag_v2
    assert 270 in tags, sorted(tags.keys())
    v = tags[270]
    assert v == 'r21-roundtrip', v
    print('ok description=%r' % v)
PY
