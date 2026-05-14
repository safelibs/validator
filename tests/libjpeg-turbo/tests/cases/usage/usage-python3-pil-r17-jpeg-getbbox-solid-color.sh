#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-jpeg-getbbox-solid-color
# @title: Pillow getbbox on a solid-color JPEG returns the full image rectangle
# @description: Saves a 32x24 solid-non-black RGB color (140,90,200) JPEG via Pillow and asserts the reopened image's getbbox() is exactly (0, 0, 32, 24), exercising libjpeg-turbo decode of a uniform color image where every pixel is non-zero so the bounding box covers the full canvas.
# @timeout: 60
# @tags: usage, jpeg, python, getbbox
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

base = Path(sys.argv[1])
out = base / "solid.jpg"
W, H = 32, 24
src = Image.new("RGB", (W, H), color=(140, 90, 200))
src.save(out, "JPEG", quality=95)

with Image.open(out) as im:
    im.load()
    box = im.getbbox()
    assert box == (0, 0, W, H), box
    assert im.mode == "RGB", im.mode
PY
