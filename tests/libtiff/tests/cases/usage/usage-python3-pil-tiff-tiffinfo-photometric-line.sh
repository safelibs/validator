#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffinfo-photometric-line
# @title: Pillow TIFF tiffinfo Photometric Interpretation line
# @description: Writes an RGB TIFF with Pillow then runs the tiffinfo CLI and verifies the Photometric Interpretation line is reported with the RGB color descriptor.
# @timeout: 180
# @tags: usage, image, python, cli, color
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/photometric.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image

path = sys.argv[1]
size = (24, 16)
pixels = [
    ((x * 11) % 256, (y * 7) % 256, ((x + y) * 13) % 256)
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
validator_assert_contains "$report" "Photometric Interpretation:"
validator_assert_contains "$report" "RGB color"
