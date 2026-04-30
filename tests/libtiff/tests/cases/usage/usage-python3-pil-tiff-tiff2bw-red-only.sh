#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiff2bw-red-only
# @title: Pillow TIFF tiff2bw -R red-only weight
# @description: Writes an RGB TIFF with Pillow whose pixels have a known red channel, runs tiff2bw with -R 100 -G 0 -B 0 (red-only weighting; tiff2bw treats -R/-G/-B as percentages, so 100/0/0 means 100% red contribution), and verifies the resulting grayscale pixel values match the original red channel and PhotometricInterpretation is 1.
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

path = sys.argv[1]
size = (16, 12)
pixels = [
    (((x * 17 + y * 5) % 256), ((x * 3 + y * 11) % 256), ((x * 7 + y * 13) % 256))
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(path)
PY

validator_require_file "$rgb"
# -R 100 -G 0 -B 0 -> 100% red weighting; tiff2bw interprets the weights as
# percentages, so the output luma equals the source R channel.
tiff2bw -R 100 -G 0 -B 0 "$rgb" "$gray"
validator_require_file "$gray"

python3 - <<'PY' "$rgb" "$gray"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as src, Image.open(sys.argv[2]) as bw:
    src.load(); bw.load()
    assert bw.mode == "L", bw.mode
    assert bw.size == src.size, (bw.size, src.size)
    photo = bw.tag_v2.get(262)
    assert photo == 1, ("photometric", photo)
    src_r = [p[0] for p in src.getdata()]
    bw_v = list(bw.getdata())
    assert src_r == bw_v, "red-only luma must equal source red channel"
    print("red-only", photo, bw.size)
PY
