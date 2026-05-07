#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-dpi-72-tuple-roundtrip
# @title: PIL TIFF dpi=(72,72) round-trips through image.info["dpi"]
# @description: Saves an RGB TIFF with dpi=(72,72) and verifies image.info["dpi"] on reopen evaluates to (72.0, 72.0) when each entry is cast to float, asserting Pillow's TIFF reader pulls XResolution/YResolution into the info dict consistent with the libtiff write of those rationals at the screen-typical 72 dpi.
# @timeout: 60
# @tags: usage, tiff, python, dpi, info
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/dpi72.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (10, 10), (20, 40, 80)).save(sys.argv[1], 'TIFF', dpi=(72, 72))

with Image.open(sys.argv[1]) as im:
    im.load()
    dpi = im.info.get('dpi')
    assert dpi is not None, 'missing dpi info'
    pair = tuple(float(v) for v in dpi)
    assert pair == (72.0, 72.0), ('dpi', pair)
PY
