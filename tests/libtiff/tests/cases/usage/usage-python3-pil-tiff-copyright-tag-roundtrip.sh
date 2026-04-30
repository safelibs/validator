#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-copyright-tag-roundtrip
# @title: Pillow TIFF Copyright tag round-trip
# @description: Saves a TIFF with a Copyright tag (33432) injected via ImageFileDirectory_v2 and verifies the string round-trips through libtiff on reload.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/copyright.tiff"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

path = sys.argv[1]
notice = "Copyright (c) 2024 validator-libtiff-round4. All rights reserved."
image = Image.new("RGB", (6, 4), (250, 100, 50))
ifd = ImageFileDirectory_v2()
ifd[33432] = notice
image.save(path, tiffinfo=ifd)

with Image.open(path) as reopened:
    reopened.load()
    stored = reopened.tag_v2.get(33432)
    assert stored == notice, stored
    assert "validator-libtiff-round4" in stored, stored
    assert reopened.size == (6, 4), reopened.size
    assert reopened.mode == "RGB", reopened.mode
    print("copyright", repr(stored))
PY
