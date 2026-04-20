#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/deflate.tiff"
from PIL import Image
import sys

size = (5, 4)
pixels = [
    ((x * 31 + y * 7) % 256, (x * 17 + y * 29) % 256, (x * 47 + y * 11) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1], compression="tiff_adobe_deflate")

with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    assert reopened.mode == "RGB", reopened.mode
    assert reopened.size == size, reopened.size
    print("tiff", reopened.mode, reopened.size)
PY
