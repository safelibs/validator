#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-bigtiff-pillow-kwarg-roundtrip
# @title: Pillow TIFF bigtiff=True save kwarg accepted and pixel round-trip preserved
# @description: Saves an RGB TIFF with the Pillow bigtiff=True kwarg, verifies the file begins with one of the legal TIFF magic byte sequences (classic II/MM or BigTIFF II\\x2b/MM\\x2b — Pillow 10.2 may emit either), and asserts the reopened image preserves geometry, mode, and exact pixel bytes against the in-memory original.
# @timeout: 180
# @tags: usage, image, python, bigtiff
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/big.tiff"
import sys
from PIL import Image

path = sys.argv[1]
size = (32, 24)
pixels = [
    ((x * 5) % 256, (y * 7 + 30) % 256, ((x + y) * 11) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
expected_bytes = image.tobytes()
image.save(path, bigtiff=True)

with open(path, "rb") as fh:
    head = fh.read(4)

legal = {
    b"II*\x00",        # classic little-endian
    b"MM\x00*",        # classic big-endian
    b"II\x2b\x00",     # BigTIFF little-endian
    b"MM\x00\x2b",     # BigTIFF big-endian
}
assert head in legal, head

with Image.open(path) as reopened:
    reopened.load()
    assert reopened.mode == "RGB", reopened.mode
    assert reopened.size == size, reopened.size
    assert reopened.tobytes() == expected_bytes, "RGB pixel bytes diverged"
    print("bigtiff-kwarg", head, reopened.size)
PY
