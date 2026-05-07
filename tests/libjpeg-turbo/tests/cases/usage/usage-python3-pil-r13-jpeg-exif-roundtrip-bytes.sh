#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-jpeg-exif-roundtrip-bytes
# @title: Pillow JPEG exif= argument round-trips through info["exif"]
# @description: Builds a minimal Exif blob via PIL.Image.Exif, saves a JPEG with that exif=... payload, and asserts the reopened JPEG exposes the same Orientation tag value through info["exif"]/getexif(), exercising the APP1 Exif marker writer/reader.
# @timeout: 60
# @tags: usage, jpeg, python, metadata
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
out = base / "exif.jpg"
src = Image.new("RGB", (24, 16))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x + y) * 3) & 255)
             for y in range(16) for x in range(24)])

exif = Image.Exif()
exif[0x0112] = 6  # Orientation = 6 (rotated 270 CW)
src.save(out, "JPEG", quality=80, exif=exif.tobytes())

# Verify APP1 Exif segment is present in the file bytes.
data = out.read_bytes()
assert b"Exif\x00\x00" in data[:512], "missing APP1 Exif marker"

with Image.open(out) as im:
    im.load()
    got = im.getexif()
    assert got.get(0x0112) == 6, got.get(0x0112)
PY
