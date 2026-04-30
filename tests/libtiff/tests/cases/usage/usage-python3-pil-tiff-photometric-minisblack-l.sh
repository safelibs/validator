#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-photometric-minisblack-l
# @title: Pillow TIFF photometric minisblack
# @description: Writes a grayscale TIFF and verifies the PhotometricInterpretation tag equals 1 (minisblack) on reload.
# @timeout: 180
# @tags: usage, image, python, photometric
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/gray.tiff"
from PIL import Image
import sys

path = sys.argv[1]
size = (12, 8)
pixels = bytes(((x * 13 + y * 17) % 256) for y in range(size[1]) for x in range(size[0]))
image = Image.frombytes("L", size, pixels)
image.save(path)

with Image.open(path) as reopened:
    reopened.load()
    photometric = reopened.tag_v2.get(262)
    assert photometric == 1, photometric
    assert reopened.mode == "L", reopened.mode
    assert reopened.size == size, reopened.size
    assert reopened.tobytes() == pixels, "pixel round-trip mismatch"
    print("minisblack", photometric, reopened.size)
PY
