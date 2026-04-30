#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffmedian-palette-reduce
# @title: Pillow TIFF tiffmedian palette reduction
# @description: Writes an RGB TIFF with Pillow, runs tiffmedian -c 16 to produce a palette TIFF, and verifies PhotometricInterpretation=3 (RGB Palette), BitsPerSample=8 and PIL mode P on reload.
# @timeout: 180
# @tags: usage, image, python, cli, palette
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

rgb="$tmpdir/rgb.tiff"
pal="$tmpdir/pal.tiff"

python3 - <<'PY' "$rgb"
import sys
from PIL import Image

size = (32, 24)
pixels = [
    ((x * 11 + y * 5) % 256, (x * 7 + y * 13) % 256, (x * 3 + y * 19) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$rgb"
# tiffmedian uses -C # for the colormap entry count (lowercase -c is for compression).
tiffmedian -C 16 "$rgb" "$pal"
validator_require_file "$pal"

python3 - <<'PY' "$pal"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    photo = im.tag_v2.get(262)
    bps_raw = im.tag_v2.get(258)
    bps = bps_raw[0] if hasattr(bps_raw, "__len__") else bps_raw
    cmap = im.tag_v2.get(320)
    assert im.mode == "P", im.mode
    assert photo == 3, ("photometric", photo)
    assert bps == 8, ("bits_per_sample", bps_raw)
    assert cmap is not None, "missing ColorMap (320)"
    # ColorMap has 3 * 2**bps entries (R,G,B all together).
    cmap_len = len(cmap) if hasattr(cmap, "__len__") else 0
    assert cmap_len == 3 * (2 ** bps), cmap_len
    assert im.size == (32, 24), im.size
    print("palette", photo, bps, cmap_len)
PY
