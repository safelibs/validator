#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-page-name-document-name-tags
# @title: Pillow TIFF PageName and DocumentName tag round-trip
# @description: Saves a TIFF with DocumentName (269) and PageName (285) injected via ImageFileDirectory_v2 and verifies both strings round-trip through libtiff and reload exactly via Pillow tag_v2.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/doc.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

ifd = ImageFileDirectory_v2()
ifd[269] = "validator-document.tif"
ifd[285] = "page-cover-1"
image = Image.new("RGB", (8, 6), (100, 150, 200))
image.save(sys.argv[1], tiffinfo=ifd)

with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    doc = reopened.tag_v2.get(269)
    page = reopened.tag_v2.get(285)
    assert doc == "validator-document.tif", doc
    assert page == "page-cover-1", page
    print("named", repr(doc), repr(page))
PY
