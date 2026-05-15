#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-tiff-newsubfiletype-tag-254-zero
# @title: Pillow TIFF NewSubfileType tag 254 absent or zero for a standalone single-image save
# @description: Saves a single-image RGB TIFF, reopens with Pillow, and asserts the optional NewSubfileType tag 254 either is missing from tag_v2 or evaluates to integer 0 (no reduced-resolution, page, or mask flags set), confirming libtiff omits or clears the subfile classification on a plain primary image.
# @timeout: 60
# @tags: usage, tiff, python, subfiletype, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/single.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (4, 4)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    v = im.tag_v2.get(254)
    if v is None:
        print('ok subfiletype absent')
    else:
        assert int(v) == 0, ('subfiletype', v)
        print('ok subfiletype=%d' % int(v))
PY
