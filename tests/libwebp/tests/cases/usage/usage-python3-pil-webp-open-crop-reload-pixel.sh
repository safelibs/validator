#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-open-crop-reload-pixel
# @title: Pillow opens WebP, crops with Image.crop, saves+reloads, checks corner pixels
# @description: Opens a WebP fixture with Pillow, crops a 5x4 sub-rectangle via Image.crop, saves the crop as lossless WebP, reloads it, and asserts both the size and the four corner pixel RGB values match the corresponding pixels in the source crop.
# @timeout: 180
# @tags: usage, webp, python, crop
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.webp"
from PIL import Image
import sys
w, h = 12, 9
src = Image.new("RGB", (w, h), (0, 0, 0))
for y in range(h):
    for x in range(w):
        src.putpixel((x, y), ((x * 23) % 256, (y * 41) % 256, ((x + y) * 19) % 256))
src.save(sys.argv[1], "WEBP", lossless=True, method=4)
PY

python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/crop.webp"
from PIL import Image
import sys

box = (3, 2, 8, 6)  # 5x4 crop
with Image.open(sys.argv[1]) as src:
    src.load()
    assert src.format == "WEBP"
    cropped = src.crop(box)
    cropped.save(sys.argv[2], "WEBP", lossless=True, method=4)
    expected_corners = [
        src.convert("RGB").getpixel((box[0],     box[1])),
        src.convert("RGB").getpixel((box[2] - 1, box[1])),
        src.convert("RGB").getpixel((box[0],     box[3] - 1)),
        src.convert("RGB").getpixel((box[2] - 1, box[3] - 1)),
    ]

with Image.open(sys.argv[2]) as out:
    out.load()
    assert out.format == "WEBP", out.format
    assert out.size == (5, 4), out.size
    rgb = out.convert("RGB")
    got_corners = [
        rgb.getpixel((0, 0)),
        rgb.getpixel((4, 0)),
        rgb.getpixel((0, 3)),
        rgb.getpixel((4, 3)),
    ]
    assert got_corners == expected_corners, (got_corners, expected_corners)
    print("crop-reload-corners", out.size, got_corners)
PY

file "$tmpdir/crop.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'
