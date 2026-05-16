#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-jpeg-tile-decoder-extents
# @title: Pillow's JPEG tile descriptor reports decoder name jpeg and full-image extents
# @description: Encodes a 56x40 RGB JPEG, re-opens it through Pillow, and asserts the JpegImageFile.tile list has exactly one entry whose decoder name is "jpeg" and whose extents tuple is (0, 0, 56, 40) covering the full image - locking in libjpeg-turbo's single-tile lazy-decoder descriptor used by Pillow to defer the actual decode pass.
# @timeout: 120
# @tags: usage, jpeg, python, tile-decoder, r21
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
out = base / "tiles.jpg"
src = Image.new("RGB", (56, 40))
src.putdata([((x * 11) & 255, (y * 13) & 255, ((x + y) * 7) & 255)
             for y in range(40) for x in range(56)])
src.save(out, "JPEG", quality=85)

with Image.open(out) as im:
    tile = im.tile
    assert isinstance(tile, list) and len(tile) == 1, tile
    decoder, extents, offset, args = tile[0]
    assert decoder == "jpeg", decoder
    assert extents == (0, 0, 56, 40), extents
PY
