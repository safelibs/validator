#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-image-description-tag
# @title: Pillow TIFF image description tag
# @description: Saves a TIFF with a custom ImageDescription (tag 270) injected via tiffinfo and verifies the string round-trips on reload.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/desc.tiff"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

path = sys.argv[1]
description = "validator-libtiff-usage-round2"
image = Image.new("RGB", (5, 4), (200, 100, 50))
ifd = ImageFileDirectory_v2()
ifd[270] = description
image.save(path, tiffinfo=ifd)

with open(path, "rb") as fh:
    head = fh.read(4)
assert head[:2] in (b"II", b"MM"), head

with Image.open(path) as reopened:
    reopened.load()
    stored = reopened.tag_v2.get(270)
    assert stored == description, stored
    info_desc = reopened.info.get("description")
    if info_desc is not None:
        assert info_desc == description, info_desc
    assert reopened.size == (5, 4), reopened.size
    assert reopened.mode == "RGB", reopened.mode
    print("description", repr(stored))
PY
