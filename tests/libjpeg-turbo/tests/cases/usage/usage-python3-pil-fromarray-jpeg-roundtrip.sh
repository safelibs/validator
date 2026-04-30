#!/usr/bin/env bash
# @testcase: usage-python3-pil-fromarray-jpeg-roundtrip
# @title: Pillow Image.fromarray (np-like) JPEG roundtrip
# @description: Builds an image from a bytes subclass exposing __array_interface__ via Image.fromarray, saves as JPEG, and verifies the roundtrip via PIL and file magic.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-fromarray-jpeg-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

class NpLikeArray(bytes):
    """Minimal numpy-free stand-in that satisfies Image.fromarray."""
    def __new__(cls, data, shape):
        obj = super().__new__(cls, data)
        obj.__array_interface__ = {
            'shape': shape,
            'typestr': '|u1',
            'data': bytes(data),
            'version': 3,
        }
        return obj

w, h = 16, 12
pixels = bytearray()
for y in range(h):
    for x in range(w):
        pixels += bytes([(x * 17) & 0xFF, (y * 23) & 0xFF, ((x + y) * 11) & 0xFF])

arr = NpLikeArray(bytes(pixels), (h, w, 3))
im = Image.fromarray(arr, 'RGB')
assert im.size == (w, h), im.size
assert im.mode == 'RGB'
assert im.getpixel((0, 0)) == (0, 0, 0)
assert im.getpixel((1, 0)) == (17, 0, 11)

out = tmpdir / 'out.jpg'
im.save(out, 'JPEG', quality=95, subsampling=0)

with Image.open(out) as reopened:
    assert reopened.format == 'JPEG'
    assert reopened.mode == 'RGB'
    assert reopened.size == (w, h)
    assert reopened.info  # populated dict (e.g. jfif markers)
    print('fromarray', reopened.size, reopened.mode)
PYCASE

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
