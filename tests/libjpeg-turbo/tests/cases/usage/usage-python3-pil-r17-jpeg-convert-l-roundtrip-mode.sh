#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-jpeg-convert-l-roundtrip-mode
# @title: Pillow Image.convert("L") then save JPEG re-decodes in mode L
# @description: Builds a 32x20 RGB image with Pillow, converts to mode "L" via convert("L"), saves as JPEG, and asserts the re-decoded image has format=JPEG, mode=L, and the original dimensions, exercising libjpeg-turbo's grayscale encode path through Pillow's convert("L") path (distinct from frombytes-mode-L which constructs from scratch).
# @timeout: 60
# @tags: usage, jpeg, python, convert-l
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
out = base / "convert-l.jpg"

W, H = 32, 20
src = Image.new("RGB", (W, H))
src.putdata([((x * 3) & 255, (y * 5) & 255, ((x + y) * 7) & 255)
             for y in range(H) for x in range(W)])
src.convert("L").save(out, "JPEG", quality=85)

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.mode == "L", im.mode
    assert im.size == (W, H), im.size
PY
