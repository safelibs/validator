#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-predictor-deflate-roundtrip
# @title: Pillow TIFF predictor deflate round-trip
# @description: Writes a deflate-compressed TIFF with horizontal differencing predictor and verifies sha256 byte round-trip.
# @timeout: 180
# @tags: usage, image, python, compression, predictor
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/predictor.tiff"
import hashlib
import sys
from PIL import Image

path = sys.argv[1]
size = (16, 12)
data = bytes((i * 7 + 3) % 256 for i in range(size[0] * size[1] * 3))
image = Image.frombytes("RGB", size, data)
image.save(path, compression="tiff_deflate", tiffinfo={317: 2})

source_digest = hashlib.sha256(data).hexdigest()
with Image.open(path) as reopened:
    reopened.load()
    assert reopened.tag_v2.get(317) == 2, reopened.tag_v2.get(317)
    compression = reopened.info.get("compression")
    assert compression in ("tiff_deflate", "tiff_adobe_deflate"), compression
    out = reopened.tobytes()
    out_digest = hashlib.sha256(out).hexdigest()
    assert out == data, "round-trip mismatch"
    assert out_digest == source_digest, (out_digest, source_digest)
    print("predictor", compression, out_digest)
PY
