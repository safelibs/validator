#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-raw-uncompressed-compression-tag-1
# @title: PIL TIFF saved with compression='raw' sets Compression tag 1 (none)
# @description: Saves an RGB TIFF with Pillow compression='raw' and verifies tag_v2[259] == 1 (no compression), exercising the explicit no-compression Pillow alias.
# @timeout: 60
# @tags: usage, tiff, python, compression, raw
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/raw.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (16, 16), (33, 66, 99)).save(sys.argv[1], 'TIFF', compression='raw')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.tag_v2.get(259) == 1, ('Compression', im.tag_v2.get(259))
PY

tiffinfo "$path" | grep -E 'Compression Scheme: None' >/dev/null
