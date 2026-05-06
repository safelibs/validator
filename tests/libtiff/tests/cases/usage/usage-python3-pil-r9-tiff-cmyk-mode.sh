#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-tiff-cmyk-mode
# @title: Pillow CMYK TIFF roundtrip
# @description: Creates a CMYK image with Pillow, saves it as TIFF, reopens it, and verifies the pixel mode is CMYK with 4 channels.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.tiff" <<'PY'
import sys
from PIL import Image
img = Image.new("CMYK", (8, 6), (40, 80, 120, 200))
img.save(sys.argv[1], "TIFF")
with Image.open(sys.argv[1]) as ro:
    ro.load()
    assert ro.mode == "CMYK", ro.mode
    assert ro.size == (8, 6)
    band = ro.split()
    assert len(band) == 4, len(band)
PY
