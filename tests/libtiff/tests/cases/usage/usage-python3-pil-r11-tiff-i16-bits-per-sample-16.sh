#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-tiff-i16-bits-per-sample-16
# @title: PIL I;16 grayscale TIFF reports BitsPerSample 16
# @description: Saves a Pillow mode='I;16' grayscale TIFF and verifies tag_v2[258] BitsPerSample == 16 and tiffinfo reports "Bits/Sample: 16", reflecting the 16-bit unsigned integer sample format used by I;16 grayscale.
# @timeout: 60
# @tags: usage, tiff, python, depth, sixteen-bit
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/g16.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('I;16', (40, 30), 65535).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    bps = im.tag_v2.get(258)
    if isinstance(bps, tuple):
        assert all(int(v) == 16 for v in bps), ('BitsPerSample', bps)
    else:
        assert int(bps) == 16, ('BitsPerSample', bps)
PY

tiffinfo "$path" | grep -E 'Bits/Sample: 16' >/dev/null
