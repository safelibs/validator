#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-jpeg-imageops-expand-border
# @title: ImageOps.expand grows a JPEG by symmetric border on every side
# @description: Loads a JPEG, expands it by an explicit pixel border using ImageOps.expand with a black fill, re-saves as JPEG, and asserts the new dimensions equal the original plus 2 * border on each axis.
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
src = Image.new("RGB", (32, 24))
src.putdata([(i & 255, (i * 3) & 255, (i * 7) & 255) for i in range(32 * 24)])
src.save(base + "/in.jpg", "JPEG", quality=85)

with Image.open(base + "/in.jpg") as im:
    im.load()
    bordered = ImageOps.expand(im, border=4, fill=(0, 0, 0))
    assert bordered.size == (40, 32), bordered.size
    bordered.save(base + "/out.jpg", "JPEG", quality=85)

with Image.open(base + "/out.jpg") as im:
    im.load()
    assert im.size == (40, 32), im.size
    assert im.mode == "RGB", im.mode
PY
