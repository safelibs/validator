#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-fillorder-default-msb2lsb
# @title: Pillow TIFFs default to FillOrder MSB2LSB (1)
# @description: Saves a default RGB TIFF with Pillow and reads tag 266 back, asserting FillOrder defaults to 1 (MSB-to-LSB) when not explicitly set, matching the libtiff baseline.
# @timeout: 120
# @tags: usage, tiff, python, fillorder
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/fo.tiff"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new("RGB", (16, 16), (1, 2, 3)).save(sys.argv[1], "TIFF")
with Image.open(sys.argv[1]) as im:
    fillorder = im.tag_v2.get(266, 1)  # libtiff default is 1 when omitted
    if fillorder != 1:
        raise SystemExit(f"FillOrder={fillorder!r}, want 1 (MSB-to-LSB)")
PY

validator_require_file "$path"
