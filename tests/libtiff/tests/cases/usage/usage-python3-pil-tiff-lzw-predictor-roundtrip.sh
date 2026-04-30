#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-lzw-predictor-roundtrip
# @title: Pillow TIFF LZW with predictor round-trip
# @description: Writes an LZW-compressed TIFF with horizontal differencing predictor (317=2) and verifies sha256 byte round-trip plus the Compression tag.
# @timeout: 180
# @tags: usage, image, python, compression, predictor
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/lzw.tiff"
import hashlib
import sys
from PIL import Image

path = sys.argv[1]
size = (24, 16)
data = bytes((i * 11 + 17) % 256 for i in range(size[0] * size[1] * 3))
image = Image.frombytes("RGB", size, data)
image.save(path, compression="tiff_lzw", tiffinfo={317: 2})

source_digest = hashlib.sha256(data).hexdigest()
with Image.open(path) as reopened:
    reopened.load()
    compression = reopened.info.get("compression")
    tag = reopened.tag_v2.get(259)
    predictor = reopened.tag_v2.get(317)
    assert compression == "tiff_lzw", compression
    assert tag == 5, tag
    assert predictor == 2, predictor
    out = reopened.tobytes()
    assert out == data, "round-trip mismatch"
    out_digest = hashlib.sha256(out).hexdigest()
    assert out_digest == source_digest, (out_digest, source_digest)
    print("lzw-predictor", compression, tag, predictor, out_digest)
PY
