#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-tiff-packbits-compression-tag
# @title: PIL TIFF saved with packbits sets Compression tag to 32773
# @description: Saves an RGB TIFF with Pillow compression='packbits' and verifies tag_v2[259] == 32773 (PackBits) and tiffinfo reports "Compression Scheme: PackBits".
# @timeout: 60
# @tags: usage, tiff, python, compression, packbits
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/packbits.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (24, 16), (200, 100, 50)).save(sys.argv[1], 'TIFF', compression='packbits')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.tag_v2.get(259) == 32773, ('Compression', im.tag_v2.get(259))
PY

tiffinfo "$path" | grep -E 'Compression Scheme: PackBits' >/dev/null
