#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-tiff-resolution-tag
# @title: Pillow TIFF resolution tag roundtrip
# @description: Saves a TIFF with a 300 dpi resolution tuple via Pillow and verifies the reopened image carries the same resolution metadata.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/dpi.tiff" <<'PY'
import sys
from PIL import Image
img = Image.new("RGB", (4, 4), (123, 45, 67))
img.save(sys.argv[1], dpi=(300, 300))
with Image.open(sys.argv[1]) as ro:
    ro.load()
    info_dpi = ro.info.get("dpi")
    assert info_dpi is not None, ro.info
    rx, ry = info_dpi
    assert int(round(rx)) == 300 and int(round(ry)) == 300, info_dpi
PY
