#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffinfo-cli-inspect
# @title: Pillow TIFF tiffinfo CLI inspect
# @description: Writes a TIFF with Pillow then runs the tiffinfo CLI and verifies key tag lines (ImageWidth, ImageLength, BitsPerSample) appear in the report.
# @timeout: 180
# @tags: usage, image, python, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/inspect.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image

path = sys.argv[1]
size = (40, 24)
pixels = [
    ((x * 6) % 256, (y * 9) % 256, ((x + y) * 4) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(path)
PY

validator_require_file "$img"

report="$tmpdir/info.txt"
tiffinfo "$img" >"$report"
validator_assert_contains "$report" "Image Width:"
validator_assert_contains "$report" "40"
validator_assert_contains "$report" "Image Length:"
validator_assert_contains "$report" "24"
validator_assert_contains "$report" "Bits/Sample:"
validator_assert_contains "$report" "Samples/Pixel:"

python3 - <<'PY' "$img"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.size == (40, 24), im.size
    assert im.mode == "RGB", im.mode
    print("inspect", im.size, im.mode)
PY
