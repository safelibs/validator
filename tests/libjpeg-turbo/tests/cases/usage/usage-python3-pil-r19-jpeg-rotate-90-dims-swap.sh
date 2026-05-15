#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-jpeg-rotate-90-dims-swap
# @title: Pillow rotate 90 with expand on a JPEG swaps width and height
# @description: Saves a 48x24 RGB JPEG via Pillow, opens it, calls rotate(90, expand=True), saves the rotated image as JPEG, and asserts the reopened rotated image's .size equals (24, 48) exactly, exercising libjpeg-turbo encode/decode bracketed around a 90-degree rotation that exchanges the axes.
# @timeout: 60
# @tags: usage, jpeg, python, rotate, dims, r19
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
a = base / "a.jpg"
b = base / "b.jpg"
W, H = 48, 24
src = Image.new("RGB", (W, H))
src.putdata([((x * 7) & 255, (y * 13) & 255, ((x ^ y) * 5) & 255)
             for y in range(H) for x in range(W)])
src.save(a, "JPEG", quality=85)

with Image.open(a) as im:
    im.load()
    rot = im.rotate(90, expand=True)
    rot.save(b, "JPEG", quality=85)

with Image.open(b) as im2:
    im2.load()
    assert im2.size == (H, W), im2.size
    assert im2.format == "JPEG", im2.format
PY
