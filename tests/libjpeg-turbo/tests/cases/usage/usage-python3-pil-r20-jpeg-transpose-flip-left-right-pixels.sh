#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-jpeg-transpose-flip-left-right-pixels
# @title: Pillow Image.transpose FLIP_LEFT_RIGHT swaps leftmost and rightmost JPEG columns
# @description: Saves an RGB JPEG with a deterministic column-dependent pattern, decodes it, applies transpose(Image.FLIP_LEFT_RIGHT), and asserts pixel (0,y) of the flipped image equals pixel (W-1,y) of the source for several rows (allowing ~4 unit drift per channel for JPEG compression), exercising libjpeg-turbo decode followed by Pillow's horizontal-flip pixel mapping.
# @timeout: 120
# @tags: usage, jpeg, python, transpose, flip, r20
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
out = base / "in.jpg"
W, H = 40, 24
src = Image.new("RGB", (W, H))
src.putdata([((x * 6) & 255, 100, ((W - 1 - x) * 6) & 255)
             for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=95)

with Image.open(out) as im:
    im.load()
    flipped = im.transpose(Image.FLIP_LEFT_RIGHT)
    assert flipped.size == im.size, (flipped.size, im.size)
    for y in (0, H // 2, H - 1):
        src_right = im.getpixel((W - 1, y))
        flp_left = flipped.getpixel((0, y))
        for a, b in zip(src_right, flp_left):
            assert abs(a - b) <= 4, (a, b, y)
PY
