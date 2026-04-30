#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-lossless-alpha-pixel-exact
# @title: Pillow lossless RGBA WebP per-pixel exact roundtrip
# @description: Saves a synthesized RGBA image with varying alpha values per pixel to lossless WebP via Pillow, reloads it, and asserts every pixel including its alpha channel matches the original byte-for-byte.
# @timeout: 180
# @tags: usage, webp, python, lossless, alpha
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/out.webp"
from PIL import Image
import sys

w, h = 4, 3
src = Image.new("RGBA", (w, h))
expected = []
for y in range(h):
    for x in range(w):
        r = (x * 71 + 3) % 256
        g = (y * 53 + 7) % 256
        b = ((x ^ y) * 89 + 11) % 256
        a = (x * 64 + y * 32 + 1) % 256
        src.putpixel((x, y), (r, g, b, a))
        expected.append((r, g, b, a))

src.save(sys.argv[1], "WEBP", lossless=True, method=4, exact=True)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == "WEBP", im.format
    assert im.mode == "RGBA", im.mode
    assert im.size == (w, h), im.size
    got = []
    for y in range(h):
        for x in range(w):
            got.append(im.getpixel((x, y)))
    assert got == expected, (got, expected)
    print("alpha-exact", im.size, im.mode)
PY

file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'
