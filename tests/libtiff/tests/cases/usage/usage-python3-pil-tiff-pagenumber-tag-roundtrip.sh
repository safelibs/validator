#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-pagenumber-tag-roundtrip
# @title: Pillow TIFF PageNumber tag (297) round-trips a (page, total) pair
# @description: Writes a single-page TIFF with an explicit PageNumber tag (297) of (0, 1) via tiffinfo and verifies the reopened image returns a length-2 tuple whose first entry is 0 and second is 1, demonstrating Pillow forwards the SHORT[2] tag to libtiff and reads it back without coercion.
# @timeout: 180
# @tags: usage, image, python, metadata, tags
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/pagenum.tiff"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

path = sys.argv[1]
ifd = ImageFileDirectory_v2()
ifd[297] = (0, 1)
image = Image.new("L", (5, 4), 100)
image.save(path, tiffinfo=ifd)

with Image.open(path) as reopened:
    reopened.load()
    page = reopened.tag_v2.get(297)
    assert page is not None, "PageNumber tag missing"
    assert hasattr(page, "__len__") and not isinstance(page, (str, bytes)), type(page)
    assert len(page) == 2, ("PageNumber len", page)
    assert int(page[0]) == 0, ("page index", page)
    assert int(page[1]) == 1, ("page total", page)
    assert reopened.mode == "L", reopened.mode
    assert reopened.size == (5, 4), reopened.size
    print("pagenumber", tuple(int(p) for p in page))
PY
