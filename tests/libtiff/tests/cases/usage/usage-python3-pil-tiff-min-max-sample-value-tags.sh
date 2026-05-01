#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-min-max-sample-value-tags
# @title: Pillow TIFF MinSampleValue (280) and MaxSampleValue (281) tags round-trip
# @description: Saves an L-mode TIFF with explicit MinSampleValue (tag 280) and MaxSampleValue (tag 281) values forwarded through tiffinfo and verifies the reopened image returns both tags - tolerating either scalar or 1-tuple shapes per Pillow tag_v2 conventions - while preserving the pixel mode, BitsPerSample (258) of 8, and image dimensions, demonstrating Pillow forwards SHORT-typed sample-range hints into libtiff and reads them back without coercion.
# @timeout: 180
# @tags: usage, image, python, metadata, tags
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/range.tiff"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2


def first(value):
    if isinstance(value, tuple):
        return value[0]
    return value


path = sys.argv[1]
size = (8, 6)
ifd = ImageFileDirectory_v2()
ifd[280] = 5
ifd[281] = 200
image = Image.new("L", size, 128)
image.save(path, tiffinfo=ifd)

with Image.open(path) as reopened:
    reopened.load()
    minv = first(reopened.tag_v2.get(280))
    maxv = first(reopened.tag_v2.get(281))
    bps = first(reopened.tag_v2.get(258))
    photometric = first(reopened.tag_v2.get(262))
    assert minv == 5, ("MinSampleValue", reopened.tag_v2.get(280))
    assert maxv == 200, ("MaxSampleValue", reopened.tag_v2.get(281))
    assert bps == 8, ("BitsPerSample", reopened.tag_v2.get(258))
    assert photometric == 1, ("Photometric", reopened.tag_v2.get(262))
    assert reopened.mode == "L", reopened.mode
    assert reopened.size == size, reopened.size
    print("min-max", minv, maxv, bps)
PY
