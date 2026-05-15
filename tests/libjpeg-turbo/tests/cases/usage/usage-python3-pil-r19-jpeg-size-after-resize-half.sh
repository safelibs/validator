#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-jpeg-size-after-resize-half
# @title: Pillow resize to half dims on a JPEG produces exact target dims on reopen
# @description: Saves a 64x32 RGB JPEG via Pillow, resizes the reopened image to (32, 16) with the default resampler, saves it as JPEG again, and asserts the second reopened image's .size equals (32, 16) exactly, exercising libjpeg-turbo encode/decode bracketed around Pillow's resize operation at a power-of-two downscale.
# @timeout: 60
# @tags: usage, jpeg, python, resize, half, r19
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
W, H = 64, 32
src = Image.new("RGB", (W, H))
src.putdata([((x * 5) & 255, (y * 11) & 255, ((x + y) * 7) & 255)
             for y in range(H) for x in range(W)])
src.save(a, "JPEG", quality=85)

with Image.open(a) as im:
    im.load()
    small = im.resize((W // 2, H // 2))
    small.save(b, "JPEG", quality=85)

with Image.open(b) as im2:
    im2.load()
    assert im2.size == (W // 2, H // 2), im2.size
    assert im2.format == "JPEG", im2.format
PY
