#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-tiff-photometric-grayscale-equals-1
# @title: Pillow TIFF saved from L-mode reports PhotometricInterpretation 1 (MinIsBlack)
# @description: Creates an L-mode (8-bit grayscale) Pillow image filled with value 100, saves as TIFF, reopens and asserts tag_v2[262] (PhotometricInterpretation) equals 1 (MinIsBlack) and asserts tag_v2[258] (BitsPerSample) equals 8 (or the single-element tuple (8,)), confirming libtiff records grayscale photometric metadata correctly.
# @timeout: 60
# @tags: usage, tiff, python, photometric, grayscale, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/gray.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('L', (8, 8), 100).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    p = im.tag_v2.get(262)
    bps = im.tag_v2.get(258)
    assert p == 1, ('photometric', p)
    assert bps == (8,) or bps == 8, ('bps', bps)
print('ok photometric=%d bps=%s' % (p, bps))
PY
