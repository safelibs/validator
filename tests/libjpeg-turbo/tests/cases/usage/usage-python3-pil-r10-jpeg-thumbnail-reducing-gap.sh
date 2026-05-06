#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-jpeg-thumbnail-reducing-gap
# @title: Pillow Image.thumbnail with reducing_gap downsizes JPEG
# @description: Loads a 256x192 JPEG and calls Image.thumbnail((64, 64), reducing_gap=2.0). Confirms the resulting image fits inside the box, preserves aspect ratio, and roundtrips back to a valid JPEG.
# @timeout: 180
# @tags: usage, jpeg, python, resize
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
src = base / "in.jpg"
out = base / "thumb.jpg"

img = Image.new("RGB", (256, 192))
img.putdata([((x * 3) & 255, (y * 5) & 255, ((x + y) * 2) & 255)
             for y in range(192) for x in range(256)])
img.save(src, "JPEG", quality=80)

with Image.open(src) as im:
    im.load()
    im.thumbnail((64, 64), reducing_gap=2.0)
    assert im.size[0] <= 64 and im.size[1] <= 64, im.size
    # 256:192 == 4:3, so reducing into a 64-square should give 64x48.
    assert im.size == (64, 48), im.size
    im.save(out, "JPEG", quality=80)

with Image.open(out) as probe:
    probe.load()
    assert probe.format == "JPEG"
    assert probe.size == (64, 48), probe.size
print("thumb", probe.size)
PY
