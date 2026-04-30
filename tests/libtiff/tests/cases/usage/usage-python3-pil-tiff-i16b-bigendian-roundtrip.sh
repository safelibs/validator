#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-i16b-bigendian-roundtrip
# @title: Pillow TIFF I;16B big-endian round-trip
# @description: Builds an "I;16B" big-endian 16-bit grayscale image, saves it through libtiff, and verifies the pixels round-trip with BitsPerSample=16 and SamplesPerPixel=1.
# @timeout: 180
# @tags: usage, image, python, depth, endian
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/i16b.tiff"
import hashlib
import struct
import sys
from PIL import Image

path = sys.argv[1]
size = (10, 6)
# Values use the full 16-bit range to exercise both bytes.
values = [(i * 1031) % 65536 for i in range(size[0] * size[1])]
src_bytes_be = b"".join(struct.pack(">H", v) for v in values)
image = Image.frombytes("I;16B", size, src_bytes_be)
assert image.mode == "I;16B", image.mode
image.save(path)

with Image.open(path) as reopened:
    reopened.load()
    bits = reopened.tag_v2.get(258)
    samples = reopened.tag_v2.get(277, 1)
    bits_value = bits[0] if isinstance(bits, tuple) else bits
    assert bits_value == 16, bits
    assert samples == 1, samples
    assert reopened.size == size, reopened.size
    assert reopened.mode in ("I;16", "I;16B", "I"), reopened.mode

    raw = reopened.tobytes()
    n = size[0] * size[1]
    if reopened.mode == "I;16B":
        out_vals = struct.unpack(f">{n}H", raw)
    elif reopened.mode == "I;16":
        out_vals = struct.unpack(f"<{n}H", raw)
    else:  # "I"
        out_vals = tuple(v & 0xFFFF for v in struct.unpack(f"<{n}I", raw))

assert tuple(values) == out_vals, (values[:4], out_vals[:4])
src_digest = hashlib.sha256(struct.pack(f"<{n}H", *values)).hexdigest()
out_digest = hashlib.sha256(struct.pack(f"<{n}H", *out_vals)).hexdigest()
assert src_digest == out_digest, "16-bit BE round-trip mismatch"
print("i16b", reopened.mode, bits, samples, out_vals[0])
PY
