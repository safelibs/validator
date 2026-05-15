#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-tiff-cmyk-mode-four-bands-spp-4
# @title: Pillow CMYK TIFF reports four bands and SamplesPerPixel 4
# @description: Saves a 3x3 mode-CMYK TIFF, reopens with Pillow, asserts im.getbands() returns the tuple ('C', 'M', 'Y', 'K'), and asserts the SamplesPerPixel tag 277 reads as 4, confirming libtiff writes four-channel CMYK images with correct band metadata.
# @timeout: 60
# @tags: usage, tiff, python, cmyk, samplesperpixel, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/cmyk.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

Image.new('CMYK', (3, 3), (10, 20, 30, 40)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as r:
    r.load()
    bands = r.getbands()
    assert bands == ('C', 'M', 'Y', 'K'), bands
    spp = r.tag_v2.get(277)
    v = int(spp[0]) if isinstance(spp, (tuple, list)) else int(spp)
    assert v == 4, ('spp', v)
    print('ok cmyk spp=%d' % v)
PY
