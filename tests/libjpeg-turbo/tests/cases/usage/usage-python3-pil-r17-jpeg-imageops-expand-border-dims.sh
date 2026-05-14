#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-jpeg-imageops-expand-border-dims
# @title: Pillow ImageOps.expand border=5 increases JPEG dimensions by exactly 10
# @description: Saves an RGB JPEG, reopens it, calls ImageOps.expand with border=5, re-encodes as JPEG, and asserts the resulting image's dimensions are width+10 and height+10 (5 pixels added on each side), exercising libjpeg-turbo decode/encode bracketing a Pillow border-expand operation.
# @timeout: 60
# @tags: usage, jpeg, python, imageops, expand
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image, ImageOps

base = Path(sys.argv[1])
src_path = base / "src.jpg"
out_path = base / "expanded.jpg"

W, H = 30, 22
src = Image.new("RGB", (W, H), color=(80, 160, 40))
src.save(src_path, "JPEG", quality=85)

with Image.open(src_path) as im:
    im.load()
    expanded = ImageOps.expand(im, border=5, fill=(255, 255, 255))
    expanded.save(out_path, "JPEG", quality=85)

with Image.open(out_path) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.size == (W + 10, H + 10), im.size
PY
