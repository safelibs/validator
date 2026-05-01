#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-bigtiff-write-libtiff
# @title: Pillow BigTIFF via WRITE_LIBTIFF and bigtiff flag
# @description: Saves a BigTIFF with Pillow by toggling TiffImagePlugin.WRITE_LIBTIFF and passing bigtiff=True, then verifies the file starts with the BigTIFF magic II followed by version 0x002B and reload produces the same RGB pixel buffer.
# @timeout: 180
# @tags: usage, image, python, bigtiff
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/big.tiff"

python3 - <<'PY' "$img"
import struct
import sys
from PIL import Image
from PIL import TiffImagePlugin

path = sys.argv[1]
size = (24, 16)
pixels = bytes(
    component
    for y in range(size[1])
    for x in range(size[0])
    for component in (((x * 7) % 256), ((y * 11) % 256), (((x + y) * 5) % 256))
)
image = Image.frombytes("RGB", size, pixels)

prior = TiffImagePlugin.WRITE_LIBTIFF
TiffImagePlugin.WRITE_LIBTIFF = True
try:
    image.save(path, format="TIFF", bigtiff=True, compression="tiff_deflate")
finally:
    TiffImagePlugin.WRITE_LIBTIFF = prior

with open(path, "rb") as fh:
    head = fh.read(8)
# Either II + 0x002B (LE BigTIFF) or MM + 0x002B (BE BigTIFF).
byte_order = head[:2]
assert byte_order in (b"II", b"MM"), head
fmt = "<H" if byte_order == b"II" else ">H"
version = struct.unpack(fmt, head[2:4])[0]
assert version == 0x002B, hex(version)

with Image.open(path) as reopened:
    reopened.load()
    assert reopened.size == size, reopened.size
    assert reopened.mode == "RGB", reopened.mode
    assert reopened.tobytes() == pixels, "pixel bytes diverge"
    print("bigtiff", byte_order, hex(version))
PY
