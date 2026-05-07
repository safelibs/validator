#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-resolution-unit-tag-2-inch
# @title: PIL TIFF saved with dpi=(300,300) reports ResolutionUnit=2 (inch)
# @description: Saves an RGB TIFF with Pillow dpi=(300,300) and verifies tag_v2[296] ResolutionUnit == 2 (inch) and tag_v2[282] XResolution and tag_v2[283] YResolution evaluate to 300, asserting the tag is set even when unit is the libtiff default.
# @timeout: 60
# @tags: usage, tiff, python, resolution, dpi
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/dpi.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (24, 24), (12, 34, 56)).save(sys.argv[1], 'TIFF', dpi=(300, 300))

with Image.open(sys.argv[1]) as im:
    im.load()
    unit = im.tag_v2.get(296)
    xr = im.tag_v2.get(282)
    yr = im.tag_v2.get(283)
    assert unit == 2, ('ResolutionUnit', unit)
    assert float(xr) == 300.0, ('XResolution', xr)
    assert float(yr) == 300.0, ('YResolution', yr)
PY
