#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-tiffset-software-tag
# @title: tiffset rewrites Software tag on a Pillow TIFF
# @description: Saves an RGB TIFF with Pillow, uses tiffset -s 305 to overwrite the Software tag, and verifies Pillow reads the new value back from tag_v2[305].
# @timeout: 180
# @tags: usage, tiff, python, tiffset
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/sw.tiff"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new("RGB", (8, 8), (10, 20, 30)).save(sys.argv[1], "TIFF")
PY

validator_require_file "$path"
tiffset -s 305 "validator-r10-tiffset" "$path"

python3 - "$path" <<'PY'
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    sw = im.tag_v2.get(305)
    assert sw == "validator-r10-tiffset", ("Software", sw)
PY
