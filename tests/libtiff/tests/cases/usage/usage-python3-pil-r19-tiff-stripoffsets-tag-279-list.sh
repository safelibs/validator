#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-tiff-stripoffsets-tag-279-list
# @title: Pillow TIFF StripByteCounts tag 279 enumerates positive values for an RGB save
# @description: Saves a 16x16 RGB TIFF, reopens with Pillow, asserts tag_v2[279] (StripByteCounts) is a non-empty tuple of positive integers, asserts sum(tag_v2[279]) is >= width*height*samples (3*16*16=768) which is the uncompressed payload floor, and asserts tag_v2[273] (StripOffsets) has the same number of entries as StripByteCounts, confirming libtiff strip-layout tags are populated and consistent.
# @timeout: 60
# @tags: usage, tiff, python, stripbytecounts, stripoffsets, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/strip.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

Image.new('RGB', (16, 16), (10, 20, 30)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    sbc = im.tag_v2.get(279)
    so = im.tag_v2.get(273)
    if not isinstance(sbc, tuple):
        sbc = (sbc,)
    if not isinstance(so, tuple):
        so = (so,)
    assert len(sbc) >= 1, ('len_sbc', sbc)
    for v in sbc:
        assert int(v) > 0, ('non-positive', v)
    assert len(so) == len(sbc), ('offsets/counts size mismatch', len(so), len(sbc))
    total = sum(int(v) for v in sbc)
    assert total >= 16 * 16 * 3, ('total too small', total)
print('ok strips=%d total=%d' % (len(sbc), total))
PY
