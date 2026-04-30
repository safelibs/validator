#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-transpose-flip-top-bottom-roundtrip
# @title: Pillow WebP Image.transpose FLIP_TOP_BOTTOM roundtrip
# @description: Opens a WebP fixture with Pillow, applies Image.transpose(FLIP_TOP_BOTTOM), saves the result as lossless WebP, reloads it, and asserts the dimensions are unchanged and that pixel (0,0) of the flipped image equals pixel (0, h-1) of the source.
# @timeout: 180
# @tags: usage, webp, python, transpose
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.webp"
from PIL import Image
import sys
w, h = 6, 5
src = Image.new("RGB", (w, h), (0, 0, 0))
for y in range(h):
    for x in range(w):
        src.putpixel((x, y), ((x * 37) % 256, (y * 61) % 256, ((x ^ y) * 43) % 256))
src.save(sys.argv[1], "WEBP", lossless=True, method=4)
PY

python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/flipped.webp"
from PIL import Image
import sys

with Image.open(sys.argv[1]) as src:
    src.load()
    assert src.format == "WEBP"
    src_rgb = src.convert("RGB")
    expected_top = src_rgb.getpixel((0, src.size[1] - 1))
    expected_bot = src_rgb.getpixel((0, 0))
    flipped = src.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    flipped.save(sys.argv[2], "WEBP", lossless=True, method=4)
    expected_size = src.size

with Image.open(sys.argv[2]) as out:
    out.load()
    assert out.format == "WEBP", out.format
    assert out.size == expected_size, out.size
    rgb = out.convert("RGB")
    assert rgb.getpixel((0, 0)) == expected_top, (rgb.getpixel((0, 0)), expected_top)
    assert rgb.getpixel((0, expected_size[1] - 1)) == expected_bot, (
        rgb.getpixel((0, expected_size[1] - 1)),
        expected_bot,
    )
    print("flip-top-bottom", out.size, rgb.getpixel((0, 0)))
PY

file "$tmpdir/flipped.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'
