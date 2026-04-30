#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-software-tag-roundtrip
# @title: Pillow TIFF Software tag round-trip
# @description: Saves a TIFF with a custom Software tag (305) injected via ImageFileDirectory_v2 and verifies the string survives a save/reload cycle through libtiff.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/software.tiff"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

path = sys.argv[1]
software = "validator-libtiff-round4 (python-pil)"
image = Image.new("RGB", (8, 6), (10, 20, 30))
ifd = ImageFileDirectory_v2()
ifd[305] = software
image.save(path, tiffinfo=ifd)

with open(path, "rb") as fh:
    head = fh.read(4)
assert head[:2] in (b"II", b"MM"), head

with Image.open(path) as reopened:
    reopened.load()
    stored = reopened.tag_v2.get(305)
    assert stored == software, stored
    info_software = reopened.info.get("software")
    if info_software is not None:
        assert info_software == software, info_software
    assert reopened.size == (8, 6), reopened.size
    assert reopened.mode == "RGB", reopened.mode
    print("software", repr(stored))
PY
