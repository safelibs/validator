#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-planar-configuration-save
# @title: Pillow TIFF planar configuration via tiffcp
# @description: Writes an RGB TIFF with Pillow then converts it to planar configuration with tiffcp and verifies the PlanarConfiguration tag and dimensions on reload.
# @timeout: 180
# @tags: usage, image, python, planar
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

chunky="$tmpdir/chunky.tiff"
planar="$tmpdir/planar.tiff"

python3 - <<'PY' "$chunky"
from PIL import Image
import sys

size = (12, 8)
pixels = [
    ((x * 9 + 11) % 256, (y * 17 + 5) % 256, ((x + y) * 13) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$chunky"

python3 - <<'PY' "$chunky"
from PIL import Image
import sys

with Image.open(sys.argv[1]) as im:
    im.load()
    planar = im.tag_v2.get(284, 1)
    assert planar == 1, planar
    print("chunky", planar)
PY

tiffcp -p separate "$chunky" "$planar"
validator_require_file "$planar"

python3 - <<'PY' "$planar"
from PIL import Image
import sys

with Image.open(sys.argv[1]) as im:
    im.load()
    planar = im.tag_v2.get(284)
    samples = im.tag_v2.get(277)
    assert planar == 2, planar
    assert samples == 3, samples
    assert im.size == (12, 8), im.size
    assert im.mode == "RGB", im.mode
    print("planar", planar, samples, im.size)
PY
