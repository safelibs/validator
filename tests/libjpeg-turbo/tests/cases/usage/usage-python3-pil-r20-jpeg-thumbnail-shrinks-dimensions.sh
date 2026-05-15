#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-jpeg-thumbnail-shrinks-dimensions
# @title: Pillow Image.thumbnail on a 100x60 JPEG yields dims fitting within 32x32
# @description: Saves a 100x60 RGB JPEG via Pillow, reopens it, calls im.thumbnail((32,32)), and asserts both width and height are <= 32 and at least one dimension equals 32 (the aspect-preserving bound), exercising libjpeg-turbo decode followed by Pillow's thumbnail in-place rescaling.
# @timeout: 120
# @tags: usage, jpeg, python, thumbnail, resize, r20
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
W, H = 100, 60
src = Image.new("RGB", (W, H))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x + y) * 5) & 255)
             for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=90)

with Image.open(out) as im:
    im.load()
    im.thumbnail((32, 32))
    w, h = im.size
    assert w <= 32 and h <= 32, (w, h)
    assert w == 32 or h == 32, (w, h)
    # aspect roughly preserved (100/60 ~= 1.667)
    assert abs((w / max(h, 1)) - (W / H)) < 0.2, (w, h)
PY
