#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-tiff-info-dpi-asymmetric-200x100
# @title: PIL TIFF dpi=(200,100) preserves asymmetric X/Y resolution on round-trip
# @description: Saves an RGB TIFF with an asymmetric dpi=(200,100) (XResolution != YResolution), then verifies on reopen that image.info["dpi"] cast to floats equals (200.0, 100.0), asserting libtiff retains the X and Y resolution rationals independently rather than collapsing them to a single value.
# @timeout: 60
# @tags: usage, tiff, python, dpi, info, asymmetric
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/asymmetric.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (8, 8), (1, 2, 3)).save(sys.argv[1], 'TIFF', dpi=(200, 100))

with Image.open(sys.argv[1]) as im:
    im.load()
    dpi = im.info.get('dpi')
    assert dpi is not None, 'missing dpi info'
    pair = tuple(float(v) for v in dpi)
    assert pair == (200.0, 100.0), ('dpi', pair)
PY
