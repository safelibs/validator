#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-bitspersample-rgb-triple
# @title: BitsPerSample tag is a triple of 8s for an RGB Pillow TIFF
# @description: Saves an RGB TIFF with Pillow and verifies tag_v2[258] BitsPerSample is exposed as a length-3 tuple where every entry equals 8, matching the three RGB samples per pixel.
# @timeout: 120
# @tags: usage, tiff, python, tag
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/rgb.tiff"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new("RGB", (12, 8), (5, 6, 7)).save(sys.argv[1], "TIFF")

with Image.open(sys.argv[1]) as im:
    im.load()
    bps = im.tag_v2.get(258)
    if isinstance(bps, int):
        bps = (bps,)
    assert len(bps) == 3, ("len", bps)
    assert all(int(v) == 8 for v in bps), ("values", bps)
    spp = im.tag_v2.get(277)
    assert spp == 3, ("SamplesPerPixel", spp)
PY
