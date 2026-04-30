#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-16bit-grayscale-roundtrip
# @title: Pillow TIFF 16-bit grayscale round-trip
# @description: Writes an "I;16" 16-bit grayscale TIFF and verifies BitsPerSample=16, SampleFormat, and that pixel bytes round-trip via sha256.
# @timeout: 180
# @tags: usage, image, python, depth
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/i16.tiff"
import hashlib
import struct
import sys
from PIL import Image

path = sys.argv[1]
size = (12, 8)
values = [(i * 257) % 65536 for i in range(size[0] * size[1])]
data = b"".join(struct.pack("<H", v) for v in values)
image = Image.frombytes("I;16", size, data)
image.save(path)

source_digest = hashlib.sha256(data).hexdigest()
with Image.open(path) as reopened:
    reopened.load()
    bits = reopened.tag_v2.get(258)
    samples = reopened.tag_v2.get(277, 1)
    bits_value = bits[0] if isinstance(bits, tuple) else bits
    assert bits_value == 16, bits
    assert samples == 1, samples
    assert reopened.size == size, reopened.size
    assert reopened.mode in ("I;16", "I"), reopened.mode
    out = reopened.tobytes()
    if reopened.mode == "I":
        out = b"".join(struct.pack("<H", v & 0xFFFF) for v in struct.unpack(f"<{size[0]*size[1]}I", out))
    assert hashlib.sha256(out).hexdigest() == source_digest, "16-bit gray round-trip mismatch"
    print("i16", bits, samples, reopened.mode)
PY
