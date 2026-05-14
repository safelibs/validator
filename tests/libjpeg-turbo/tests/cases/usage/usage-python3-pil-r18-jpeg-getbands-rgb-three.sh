#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-jpeg-getbands-rgb-three
# @title: Pillow getbands on an RGB JPEG returns the three-tuple R, G, B
# @description: Saves a small RGB image as JPEG via Pillow and asserts the reopened image's getbands() returns exactly the tuple ("R", "G", "B") and len(getbands()) is 3, exercising libjpeg-turbo's three-component decode through Pillow's band introspection (distinct from L-mode getbands coverage).
# @timeout: 60
# @tags: usage, jpeg, python, getbands, rgb, r18
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
out = base / "rgb.jpg"
W, H = 24, 16
src = Image.new("RGB", (W, H))
src.putdata([((x * 9) & 255, (y * 17) & 255, ((x + y) * 23) & 255)
             for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=90)

with Image.open(out) as im:
    im.load()
    bands = im.getbands()
    assert bands == ("R", "G", "B"), bands
    assert len(bands) == 3, bands
    assert im.format == "JPEG", im.format
PY
