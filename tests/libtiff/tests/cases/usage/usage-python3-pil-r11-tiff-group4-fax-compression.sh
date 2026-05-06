#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-tiff-group4-fax-compression
# @title: PIL bilevel TIFF saved with group4 reports CCITT Group 4 compression
# @description: Saves a Pillow mode='1' bilevel image to TIFF with compression='group4' and verifies tag_v2[259] == 4 (CCITT Group 4) and tiffinfo reports "Compression Scheme: CCITT Group 4".
# @timeout: 60
# @tags: usage, tiff, python, compression, fax, group4
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/g4.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('1', (40, 30), 0).save(sys.argv[1], 'TIFF', compression='group4')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.tag_v2.get(259) == 4, ('Compression', im.tag_v2.get(259))
PY

tiffinfo "$path" | grep -E 'Compression Scheme: CCITT Group 4' >/dev/null
