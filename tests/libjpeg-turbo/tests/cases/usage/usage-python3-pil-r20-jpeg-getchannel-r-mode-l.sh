#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-jpeg-getchannel-r-mode-l
# @title: Pillow Image.getchannel("R") on a decoded RGB JPEG returns mode L same size
# @description: Saves an RGB JPEG, decodes it via Pillow, calls im.getchannel("R"), and asserts the returned channel image has mode "L" and the same size as the source, exercising libjpeg-turbo decode followed by Pillow's per-channel band-projection method.
# @timeout: 120
# @tags: usage, jpeg, python, getchannel, band, r20
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
out = base / "src.jpg"
W, H = 24, 16
src = Image.new("RGB", (W, H))
src.putdata([((x * 11) & 255, (y * 9) & 255, ((x + y) * 7) & 255)
             for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=90)

with Image.open(out) as im:
    im.load()
    r = im.getchannel("R")
    assert r.mode == "L", r.mode
    assert r.size == im.size, (r.size, im.size)
PY
