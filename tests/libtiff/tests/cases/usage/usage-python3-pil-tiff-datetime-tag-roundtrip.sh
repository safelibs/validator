#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-datetime-tag-roundtrip
# @title: Pillow TIFF DateTime tag round-trip
# @description: Saves a TIFF with a DateTime tag (306) in the canonical "YYYY:MM:DD HH:MM:SS" format and verifies the value reads back unchanged via tag_v2.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/datetime.tiff"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

path = sys.argv[1]
# TIFF spec section 8: DateTime is exactly 20 ASCII bytes "YYYY:MM:DD HH:MM:SS\0".
stamp = "2024:12:31 23:45:01"
image = Image.new("L", (5, 5), 128)
ifd = ImageFileDirectory_v2()
ifd[306] = stamp
image.save(path, tiffinfo=ifd)

with Image.open(path) as reopened:
    reopened.load()
    stored = reopened.tag_v2.get(306)
    # tag_v2 strips trailing NULs but should preserve the canonical 19-char form.
    assert stored == stamp, stored
    assert len(stored) == 19, len(stored)
    assert stored[4] == ":" and stored[7] == ":" and stored[10] == " ", stored
    assert reopened.size == (5, 5), reopened.size
    assert reopened.mode == "L", reopened.mode
    print("datetime", repr(stored))
PY
