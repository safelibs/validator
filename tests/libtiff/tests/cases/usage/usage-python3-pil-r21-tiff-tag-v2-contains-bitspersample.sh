#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-tiff-tag-v2-contains-bitspersample
# @title: Pillow TiffImagePlugin tag_v2 mapping contains BitsPerSample (tag 258)
# @description: Saves a 7x7 RGB TIFF, opens it, and asserts that 258 (BitsPerSample) is present in im.tag_v2 with a tuple value of three eights, validating libtiff's tag-2-name dictionary surface for the RGB photometric path.
# @timeout: 60
# @tags: usage, tiff, python, tag-v2, bitspersample, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/rgb.tif" <<'PY'
import sys
from PIL import Image

Image.new('RGB', (7, 7), (10, 20, 30)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    tags = im.tag_v2
    assert 258 in tags, sorted(tags.keys())
    bps = tags[258]
    # BitsPerSample for RGB 8-bit must be (8, 8, 8) (tuple) or 8 (scalar) depending on Pillow version.
    if isinstance(bps, tuple):
        assert bps == (8, 8, 8), bps
    else:
        assert bps == 8, bps
    print('ok bps=%r' % (bps,))
PY
