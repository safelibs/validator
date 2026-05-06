#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-ppm2tiff-roundtrip
# @title: ppm2tiff converts a synthetic PPM into a Pillow-readable TIFF
# @description: Writes a small binary PPM, runs ppm2tiff to wrap it as TIFF, and verifies Pillow opens the result with mode RGB, the expected size, and pixel data matching the source PPM bytes.
# @timeout: 180
# @tags: usage, tiff, python, ppm2tiff
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ppm="$tmpdir/in.ppm"
tif="$tmpdir/out.tiff"

python3 - "$ppm" <<'PY'
import sys
w, h = 8, 4
header = f"P6\n{w} {h}\n255\n".encode()
pixels = bytearray()
for y in range(h):
    for x in range(w):
        pixels.extend(((x * 17) % 256, (y * 53) % 256, ((x + y) * 11) % 256))
with open(sys.argv[1], "wb") as fh:
    fh.write(header)
    fh.write(pixels)
PY

validator_require_file "$ppm"
ppm2tiff "$ppm" "$tif"
validator_require_file "$tif"

python3 - "$tif" <<'PY'
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == "RGB", im.mode
    assert im.size == (8, 4), im.size
    expected = []
    for y in range(4):
        for x in range(8):
            expected.append(((x * 17) % 256, (y * 53) % 256, ((x + y) * 11) % 256))
    assert list(im.getdata()) == expected, "pixel mismatch after ppm2tiff"
PY
