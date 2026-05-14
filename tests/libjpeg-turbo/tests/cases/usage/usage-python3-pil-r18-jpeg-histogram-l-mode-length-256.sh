#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-jpeg-histogram-l-mode-length-256
# @title: Pillow histogram on a grayscale JPEG returns a 256-bucket list summing to the pixel count
# @description: Saves a 32x16 mode-L grayscale JPEG via Pillow with quality=90, reopens it, asserts histogram() length is exactly 256 and the sum of all bins equals W*H=512 (the pixel count), exercising libjpeg-turbo's grayscale decode followed by Pillow's histogram introspection on a single-band image.
# @timeout: 60
# @tags: usage, jpeg, python, histogram, grayscale, r18
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
out = base / "gray.jpg"
W, H = 32, 16
src = Image.new("L", (W, H))
src.putdata([((x * 5 + y * 3) & 255) for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=90)

with Image.open(out) as im:
    im.load()
    assert im.mode == "L", im.mode
    hist = im.histogram()
    assert len(hist) == 256, len(hist)
    assert sum(hist) == W * H, (sum(hist), W * H)
PY
