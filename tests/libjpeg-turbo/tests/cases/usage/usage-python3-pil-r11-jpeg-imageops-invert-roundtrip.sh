#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-jpeg-imageops-invert-roundtrip
# @title: ImageOps.invert on a JPEG roundtrips through libjpeg encode and decode
# @description: Opens a saved JPEG, applies ImageOps.invert to flip every channel, re-saves as JPEG, reopens the inverted file, and asserts the geometry and mode are preserved across the encode/decode cycle.
# @timeout: 90
# @tags: usage, jpeg, python, imageops
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from PIL import Image, ImageOps

base = sys.argv[1]
src = Image.new("RGB", (40, 30))
src.putdata([(i & 255, (i * 5) & 255, (i * 11) & 255) for i in range(40 * 30)])
src.save(base + "/in.jpg", "JPEG", quality=85)

with Image.open(base + "/in.jpg") as im:
    im.load()
    inv = ImageOps.invert(im)
    inv.save(base + "/out.jpg", "JPEG", quality=85)

with Image.open(base + "/out.jpg") as im:
    im.load()
    assert im.size == (40, 30), im.size
    assert im.mode == "RGB", im.mode
    assert im.format == "JPEG", im.format
PY
