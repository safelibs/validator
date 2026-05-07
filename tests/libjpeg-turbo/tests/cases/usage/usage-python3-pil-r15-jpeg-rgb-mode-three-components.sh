#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-jpeg-rgb-mode-three-components
# @title: Pillow JPEG save of an RGB image writes a 3-component SOF marker
# @description: Builds an RGB Pillow image, saves as JPEG, and parses the SOF marker to confirm Nf == 3 components, exercising the libjpeg-turbo standard YCbCr-derived 3-channel encode path.
# @timeout: 60
# @tags: usage, jpeg, python, rgb
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
src = Image.new("RGB", (32, 24))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x ^ y) * 5) & 255)
             for y in range(24) for x in range(32)])
src.save(out, "JPEG", quality=85)

data = out.read_bytes()
i = data.find(b"\xff\xc0")
if i < 0:
    i = data.find(b"\xff\xc2")
assert i > 0, "no SOF marker"
nf = data[i + 9]
assert nf == 3, f"expected 3 components for RGB, got {nf}"

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.mode == "RGB", im.mode
    assert im.size == (32, 24), im.size
PY
