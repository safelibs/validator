#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-tiff-info-compression-string-raw
# @title: PIL TIFF saved with compression='raw' reports info["compression"] == "raw"
# @description: Saves an RGB TIFF with Pillow compression='raw' (no compression) and verifies image.info["compression"] is exactly the string "raw", asserting Pillow propagates the "uncompressed" alias verbatim through the libtiff write path on reopen.
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
Image.new('RGB', (8, 8), (1, 2, 3)).save(sys.argv[1], 'TIFF', compression='raw')

with Image.open(sys.argv[1]) as im:
    im.load()
    comp = im.info.get('compression')
    assert comp == 'raw', ('info[compression]', comp)
PY
