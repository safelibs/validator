#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-tiff-photometric-rgb-equals-2
# @title: PIL RGB TIFF reports PhotometricInterpretation tag 262 equal to 2 (RGB)
# @description: Saves a small RGB image as an uncompressed TIFF, reopens with Pillow, asserts tag_v2[262] (PhotometricInterpretation) equals integer 2 — the libtiff identifier for RGB — and asserts the image mode is RGB.
# @timeout: 60
# @tags: usage, tiff, python, photometric
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/photometric-rgb.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (5, 5), (10, 20, 30)).save(sys.argv[1], 'TIFF', compression='raw')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'RGB', ('mode', im.mode)
    photo = im.tag_v2.get(262)
    assert photo == 2, ('photometric', photo)
PY
