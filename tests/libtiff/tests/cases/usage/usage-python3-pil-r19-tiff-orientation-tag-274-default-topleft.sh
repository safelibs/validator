#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-tiff-orientation-tag-274-default-topleft
# @title: Pillow TIFF Orientation tag 274 defaults to 1 (top-left) for a plain RGB save
# @description: Saves a 4x4 RGB TIFF with no explicit orientation, reopens with Pillow, and asserts tag_v2[274] equals 1 (Orientation TopLeft, the libtiff default) or is absent (interpreted as 1 by the TIFF 6.0 spec); if absent the test additionally asserts im.getexif().get(274, 1) equals 1, confirming the canonical default orientation behavior.
# @timeout: 60
# @tags: usage, tiff, python, orientation, default, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/orient.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (4, 4)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    v = im.tag_v2.get(274)
    if v is None:
        ex = im.getexif().get(274, 1)
        assert int(ex) == 1, ('exif orientation', ex)
        print('ok orientation default (absent, exif=%d)' % int(ex))
    else:
        assert int(v) == 1, ('orientation', v)
        print('ok orientation=%d' % int(v))
PY
