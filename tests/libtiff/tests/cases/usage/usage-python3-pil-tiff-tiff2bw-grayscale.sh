#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiff2bw-grayscale
# @title: Pillow TIFF tiff2bw grayscale conversion
# @description: Writes an RGB TIFF with Pillow, converts it to grayscale with tiff2bw, and verifies SamplesPerPixel=1, PhotometricInterpretation=1 and PIL mode L on reload.
# @timeout: 180
# @tags: usage, image, python, cli, color
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

rgb="$tmpdir/rgb.tiff"
gray="$tmpdir/gray.tiff"

python3 - <<'PY' "$rgb"
import sys
from PIL import Image

size = (24, 16)
pixels = [
    ((x * 9) % 256, (y * 11) % 256, ((x + y) * 7) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$rgb"
tiff2bw "$rgb" "$gray"
validator_require_file "$gray"

python3 - <<'PY' "$gray"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    spp = im.tag_v2.get(277)
    photo = im.tag_v2.get(262)
    assert im.mode == "L", im.mode
    assert spp == 1, ("samples_per_pixel", spp)
    assert photo == 1, ("photometric", photo)
    assert im.size == (24, 16), im.size
    print("bw", im.mode, spp, photo)
PY
