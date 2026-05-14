#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-tiff-photometric-rgb-equals-2
# @title: Pillow RGB TIFF reports PhotometricInterpretation tag 262 as 2 (RGB)
# @description: Saves an RGB TIFF, reopens it with Pillow, asserts tag_v2[262] (PhotometricInterpretation) is castable to integer 2, which is libtiff's PHOTOMETRIC_RGB constant, confirming the photometric tag is encoded correctly for a standard RGB pixel layout.
# @timeout: 60
# @tags: usage, tiff, python, photometric, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/photo.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (6, 6), (200, 30, 5)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    ph = int(im.tag_v2.get(262))
    assert ph == 2, ('photometric', ph)
print('ok photometric=%d' % ph)
PY
