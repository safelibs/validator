#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-jpeg-getbands-l-mode-single
# @title: Pillow getbands on a grayscale L-mode JPEG returns the single-tuple L
# @description: Saves a grayscale L-mode JPEG via Pillow and asserts the reopened image's getbands() returns exactly the tuple ("L",) and im.mode is "L", exercising libjpeg-turbo's single-component grayscale decode through Pillow's band introspection (distinct from the r18 RGB band coverage).
# @timeout: 60
# @tags: usage, jpeg, python, getbands, grayscale, r19
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
out = base / "l.jpg"
W, H = 20, 12
src = Image.new("L", (W, H))
src.putdata([((x * 13 + y * 7) & 255) for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=90)

with Image.open(out) as im:
    im.load()
    assert im.mode == "L", im.mode
    bands = im.getbands()
    assert bands == ("L",), bands
    assert len(bands) == 1, bands
    assert im.format == "JPEG", im.format
PY
