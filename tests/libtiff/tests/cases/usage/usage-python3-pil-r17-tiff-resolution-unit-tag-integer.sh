#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-tiff-resolution-unit-tag-integer
# @title: Pillow TIFF ResolutionUnit tag 296 is a numeric value in {1,2,3}
# @description: Writes an RGB TIFF with default resolution settings, reopens it, asserts tag_v2[296] (ResolutionUnit) is an integer (or castable to one) whose value is in the libtiff-defined set {1=None, 2=Inch, 3=Centimeter}, confirming the tag round-trips as a numeric enum.
# @timeout: 60
# @tags: usage, tiff, python, resolution-unit, r17
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/resunit.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (4, 4)).save(sys.argv[1], 'TIFF', dpi=(72, 72))

with Image.open(sys.argv[1]) as im:
    im.load()
    ru = im.tag_v2.get(296)
    iv = int(ru)
    assert iv in (1, 2, 3), ('ResolutionUnit', ru, iv)
print('ok ResolutionUnit=%d' % iv)
PY
