#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-group4-bilevel-compression
# @title: Pillow TIFF group4 bilevel compression
# @description: Writes a 1-bit TIFF compressed with CCITT Group 4 and verifies the Compression tag and pixel round-trip.
# @timeout: 180
# @tags: usage, image, python, compression, fax
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/g4.tiff"
import sys
from PIL import Image

path = sys.argv[1]
size = (16, 8)
checker = Image.new("1", size, 0)
for y in range(size[1]):
    for x in range(size[0]):
        if (x + y) % 2 == 0:
            checker.putpixel((x, y), 1)
expected = checker.tobytes()
checker.save(path, compression="group4")

with Image.open(path) as reopened:
    reopened.load()
    compression = reopened.info.get("compression")
    tag = reopened.tag_v2.get(259)
    assert compression == "group4", compression
    assert tag == 4, tag
    assert reopened.mode == "1", reopened.mode
    assert reopened.size == size, reopened.size
    assert reopened.tobytes() == expected, "bilevel round-trip mismatch"
    print("group4", compression, tag, reopened.size)
PY
