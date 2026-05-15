#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-tiff-planarconfig-tag-284-chunky
# @title: Pillow TIFF PlanarConfiguration tag 284 defaults to 1 (chunky/interleaved) for an RGB save
# @description: Saves an RGB TIFF with no explicit planar configuration override, reopens with Pillow, asserts tag_v2[284] equals 1 (chunky, samples interleaved per pixel) which is libtiff's default for RGB, and asserts tag_v2[277] (SamplesPerPixel) equals 3, confirming libtiff writes an interleaved layout for plain RGB data.
# @timeout: 60
# @tags: usage, tiff, python, planarconfig, chunky, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/planar.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (8, 8), (10, 20, 30)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    pc = im.tag_v2.get(284)
    spp = im.tag_v2.get(277)
    assert pc == 1, ('planar', pc)
    assert spp == 3, ('spp', spp)
print('ok planar=%d spp=%d' % (pc, spp))
PY
