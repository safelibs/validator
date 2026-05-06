#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-jpeg-thumbnail-shrink
# @title: Pillow Image.thumbnail shrinks JPEG in-place
# @description: Calls Image.thumbnail on a 64x32 JPEG and verifies the result is shrunk to fit within an 8x8 box while preserving aspect ratio.
# @timeout: 180
# @tags: usage, jpeg, python, thumbnail
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from PIL import Image

src = sys.argv[1] + "/in.jpg"
out = sys.argv[1] + "/thumb.jpg"

Image.new("RGB", (64, 32), (10, 200, 30)).save(src, "JPEG")

with Image.open(src) as im:
    im.load()
    im.thumbnail((8, 8))
    im.save(out, "JPEG")

with Image.open(out) as probe:
    w, h = probe.size
    assert w <= 8 and h <= 8, probe.size
    # Aspect ratio 2:1 must be preserved (width >= height).
    assert w >= h, probe.size
print("ok", probe.size)
PY
