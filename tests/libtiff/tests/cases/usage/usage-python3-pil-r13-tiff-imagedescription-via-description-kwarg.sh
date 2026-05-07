#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-tiff-imagedescription-via-description-kwarg
# @title: PIL TIFF description kwarg writes ImageDescription tag 270 readable on reopen
# @description: Saves a Pillow TIFF with the description= keyword and verifies on reopen that tag_v2.get(270) (ImageDescription) returns the same ASCII string, asserting Pillow forwards the keyword into the libtiff IFD.
# @timeout: 60
# @tags: usage, tiff, python, ascii, description
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/desc.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (12, 12), (10, 10, 10)).save(
    sys.argv[1], 'TIFF', description='r13 description kwarg'
)

with Image.open(sys.argv[1]) as im:
    im.load()
    desc = im.tag_v2.get(270)
    assert desc == 'r13 description kwarg', ('ImageDescription', desc)
PY
