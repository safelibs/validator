#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-tiff-rotate-90-roundtrip
# @title: Pillow rotate 90 TIFF dimensions swap
# @description: Saves a 12x4 TIFF via Pillow, rotates the reopened image by 90 degrees with expand=True, saves the rotated TIFF, and verifies the dimensions swap to 4x12.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.tiff" "$tmpdir/out.tiff" <<'PY'
import sys
from PIL import Image
src_path, dst_path = sys.argv[1], sys.argv[2]
Image.new("RGB", (12, 4), (200, 30, 60)).save(src_path, "TIFF")

with Image.open(src_path) as ro:
    rotated = ro.rotate(90, expand=True)
    rotated.save(dst_path, "TIFF")

with Image.open(dst_path) as out:
    out.load()
    assert out.size == (4, 12), out.size
PY
