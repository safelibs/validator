#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-f-mode-float32-pixel-roundtrip
# @title: Pillow TIFF F mode float32 deterministic pixel round-trip
# @description: Builds an F mode image with deterministic float values, saves it as TIFF, and verifies that BitsPerSample is 32, SampleFormat (339) is IEEE FP (3), and per-pixel float values reload identically via Image.getpixel.
# @timeout: 180
# @tags: usage, image, python, float
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/float32.tiff"
import struct
import sys
from PIL import Image

path = sys.argv[1]
size = (5, 4)
values = [(x + 1) * 0.25 - (y * 0.5) for y in range(size[1]) for x in range(size[0])]
image = Image.new("F", size)
image.putdata(values)
image.save(path)

with Image.open(path) as reopened:
    reopened.load()
    assert reopened.mode == "F", reopened.mode
    assert reopened.size == size, reopened.size
    bps = reopened.tag_v2.get(258)
    sf = reopened.tag_v2.get(339)
    assert bps == 32, bps
    sf_val = sf[0] if hasattr(sf, "__len__") else sf
    assert sf_val == 3, sf  # 3 = IEEE floating point
    for y in range(size[1]):
        for x in range(size[0]):
            expected = values[y * size[0] + x]
            actual = reopened.getpixel((x, y))
            # Float32 round-trip: exact for these values.
            assert struct.pack("<f", expected) == struct.pack("<f", actual), (expected, actual)
    print("float32", bps, sf_val)
PY
