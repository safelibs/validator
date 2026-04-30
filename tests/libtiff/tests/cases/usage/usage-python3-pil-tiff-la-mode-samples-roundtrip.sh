#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-la-mode-samples-roundtrip
# @title: Pillow TIFF LA mode samples round-trip
# @description: Saves a Pillow LA (luminance + alpha) image as TIFF and verifies SamplesPerPixel=2, BitsPerSample=(8,8), and pixel byte round-trip.
# @timeout: 180
# @tags: usage, image, python, samples
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/la.tiff"
import hashlib
import sys
from PIL import Image

path = sys.argv[1]
size = (8, 5)
data = bytes((i * 13 + 5) % 256 for i in range(size[0] * size[1] * 2))
image = Image.frombytes("LA", size, data)
image.save(path)

source_digest = hashlib.sha256(data).hexdigest()
with Image.open(path) as reopened:
    reopened.load()
    samples = reopened.tag_v2.get(277)
    bits = reopened.tag_v2.get(258)
    assert samples == 2, samples
    if isinstance(bits, tuple):
        assert bits == (8, 8), bits
    else:
        assert bits == 8, bits
    assert reopened.size == size, reopened.size
    assert reopened.mode == "LA", reopened.mode
    out = reopened.tobytes()
    assert out == data, "LA round-trip mismatch"
    assert hashlib.sha256(out).hexdigest() == source_digest
    print("la", samples, bits, reopened.size)
PY
