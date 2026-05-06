#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-fillorder-default-msb2lsb
# @title: Pillow TIFFs default to FillOrder MSB2LSB (1)
# @description: Saves a default RGB TIFF with Pillow and verifies tiffinfo reports FillOrder as msb-to-lsb, matching the FillOrder=1 default for ordinary TIFFs.
# @timeout: 120
# @tags: usage, tiff, python, fillorder
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/fo.tiff"
info="$tmpdir/info.txt"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new("RGB", (16, 16), (1, 2, 3)).save(sys.argv[1], "TIFF")
PY

validator_require_file "$path"
tiffinfo "$path" >"$info"
validator_assert_contains "$info" "FillOrder: msb-to-lsb"
