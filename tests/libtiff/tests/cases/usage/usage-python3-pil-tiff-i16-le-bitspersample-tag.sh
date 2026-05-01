#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-i16-le-bitspersample-tag
# @title: Pillow TIFF I;16 little-endian BitsPerSample tag
# @description: Saves an I;16 little-endian grayscale TIFF and verifies BitsPerSample (258) is 16, SamplesPerPixel (277) is 1, and the raw 16-bit pixel buffer round-trips byte-exact through Pillow tobytes.
# @timeout: 180
# @tags: usage, image, python, deep
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/gray16.tiff"
import struct
import sys
from PIL import Image

path = sys.argv[1]
size = (12, 8)
values = [((x * 257 + y * 31) & 0xFFFF) for y in range(size[1]) for x in range(size[0])]
raw = b"".join(struct.pack("<H", v) for v in values)
image = Image.frombytes("I;16", size, raw)
image.save(path)

with Image.open(path) as reopened:
    reopened.load()
    bps = reopened.tag_v2.get(258)
    spp = reopened.tag_v2.get(277, 1)
    assert bps == 16, bps
    assert spp == 1, spp
    assert reopened.size == size, reopened.size
    assert reopened.mode in {"I;16", "I;16B", "I;16L"}, reopened.mode
    out = reopened.tobytes()
    if reopened.mode == "I;16B":
        # Big-endian -> swap to compare against our LE expected.
        out = b"".join(out[i+1:i+2] + out[i:i+1] for i in range(0, len(out), 2))
    assert out == raw, "16-bit pixel buffer mismatch"
    print("i16", bps, spp, len(raw))
PY
