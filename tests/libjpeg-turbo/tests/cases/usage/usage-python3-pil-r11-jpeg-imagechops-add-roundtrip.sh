#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-jpeg-imagechops-add-roundtrip
# @title: ImageChops.add of a JPEG with itself preserves geometry through encode
# @description: Loads a JPEG, calls ImageChops.add(im, im, scale=2) to combine the image with itself, saves the result as JPEG, reopens it, and asserts the geometry, mode, and JPEG format survive the channel arithmetic plus encode/decode roundtrip.
# @timeout: 90
# @tags: usage, jpeg, python, imagechops
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from PIL import Image, ImageChops

base = sys.argv[1]
src = Image.new("RGB", (32, 24))
src.putdata([(i & 255, (i * 5) & 255, (i * 9) & 255) for i in range(32 * 24)])
src.save(base + "/in.jpg", "JPEG", quality=85)

with Image.open(base + "/in.jpg") as im:
    im.load()
    combined = ImageChops.add(im, im, scale=2.0)
    assert combined.size == (32, 24), combined.size
    assert combined.mode == "RGB", combined.mode
    combined.save(base + "/out.jpg", "JPEG", quality=85)

with Image.open(base + "/out.jpg") as im:
    im.load()
    assert im.size == (32, 24), im.size
    assert im.format == "JPEG", im.format
PY
