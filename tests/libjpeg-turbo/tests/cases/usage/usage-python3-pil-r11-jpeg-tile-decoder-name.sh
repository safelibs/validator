#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-jpeg-tile-decoder-name
# @title: Pillow im.tile lists the jpeg decoder before load
# @description: Opens a saved JPEG without calling load() and asserts that im.tile is a non-empty list whose first entry's decoder name is "jpeg" — confirming Pillow wires the libjpeg-turbo decoder for files identified as JPEG.
# @timeout: 60
# @tags: usage, jpeg, python, decoder
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from PIL import Image

out = sys.argv[1] + "/dec.jpg"
src = Image.new("RGB", (24, 16))
src.putdata([(i & 255, (i * 5) & 255, (i * 11) & 255) for i in range(24 * 16)])
src.save(out, "JPEG", quality=80)

with Image.open(out) as im:
    tile = im.tile
    assert tile, tile
    decoder, region, offset, args = tile[0]
    assert decoder == "jpeg", decoder
    assert region == (0, 0, 24, 16), region
PY
