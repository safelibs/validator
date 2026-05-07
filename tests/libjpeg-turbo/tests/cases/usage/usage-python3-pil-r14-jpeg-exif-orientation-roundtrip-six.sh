#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-jpeg-exif-orientation-roundtrip-six
# @title: Pillow JPEG exif=Orientation=6 round-trips through im.getexif()
# @description: Saves a JPEG with an Exif Orientation tag (0x0112) set to 6 and re-opens to confirm im.getexif()[0x0112] == 6 on read-back, exercising the libjpeg-turbo APP1 Exif segment writer/reader.
# @timeout: 60
# @tags: usage, jpeg, python, exif
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
out = base / "ori.jpg"
src = Image.new("RGB", (24, 18), (40, 200, 100))
exif = src.getexif()
exif[0x0112] = 6  # Orientation: rotate 270 CW
src.save(out, "JPEG", quality=85, exif=exif.tobytes())

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    e = im.getexif()
    assert e.get(0x0112) == 6, e.get(0x0112)
PY
