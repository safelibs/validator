#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-16bit-grayscale-point-doubled
# @title: Pillow TIFF 16-bit grayscale point doubled
# @description: Loads an "I;16" TIFF, applies an Image.point lambda x: x*2 mapped through "I" mode to avoid 16-bit overflow, saves the result, and verifies pixels are exactly doubled (capped by I mode width).
# @timeout: 180
# @tags: usage, image, python, depth
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/in16.tiff"
out="$tmpdir/out16.tiff"

python3 - <<'PY' "$src"
import struct
import sys
from PIL import Image

path = sys.argv[1]
size = (12, 8)
# Values up to 30000 - doubling stays in unsigned 16-bit range (<= 60000).
values = [(i * 311) % 30001 for i in range(size[0] * size[1])]
data = b"".join(struct.pack("<H", v) for v in values)
image = Image.frombytes("I;16", size, data)
image.save(path)
PY

validator_require_file "$src"

python3 - <<'PY' "$src" "$out"
import struct
import sys
from PIL import Image

src, out = sys.argv[1], sys.argv[2]

with Image.open(src) as im:
    im.load()
    bits = im.tag_v2.get(258)
    bits_value = bits[0] if isinstance(bits, tuple) else bits
    assert bits_value == 16, bits

    # Convert to "I" (32-bit signed) so that point()'s lambda has headroom
    # to evaluate x*2 without overflowing the source 16-bit container.
    converted = im.convert("I")
    doubled = converted.point(lambda x: x * 2)
    assert doubled.mode == "I", doubled.mode
    # Re-cast to I;16 for round-trip - all values fit since source <= 30000.
    sixteen = doubled.convert("I;16")
    sixteen.save(out)

    src_bytes = im.tobytes()
    src_vals = struct.unpack(f"<{im.size[0]*im.size[1]}H", src_bytes)

with Image.open(out) as reopened:
    reopened.load()
    reb = reopened.tag_v2.get(258)
    reb_value = reb[0] if isinstance(reb, tuple) else reb
    assert reb_value == 16, reb
    assert reopened.size == (12, 8), reopened.size

    out_bytes = reopened.tobytes()
    if reopened.mode == "I":
        u32 = struct.unpack(f"<{reopened.size[0]*reopened.size[1]}I", out_bytes)
        out_vals = tuple(v & 0xFFFF for v in u32)
    else:
        out_vals = struct.unpack(f"<{reopened.size[0]*reopened.size[1]}H", out_bytes)

assert len(src_vals) == len(out_vals)
for i, (a, b) in enumerate(zip(src_vals, out_vals)):
    assert b == (a * 2) & 0xFFFF, (i, a, b)
print("doubled", len(src_vals), src_vals[0], out_vals[0])
PY
