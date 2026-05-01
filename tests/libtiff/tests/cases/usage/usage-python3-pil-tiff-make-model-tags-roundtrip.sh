#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-make-model-tags-roundtrip
# @title: Pillow TIFF Make and Model tag round-trip
# @description: Saves a TIFF with Make (271) and Model (272) injected via ImageFileDirectory_v2 tiffinfo and verifies tiffinfo prints both fields and Pillow tag_v2 returns the exact strings on reload.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/cam.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

ifd = ImageFileDirectory_v2()
ifd[271] = "Validator-Cam"
ifd[272] = "Model-XR-7"
image = Image.new("RGB", (10, 8), (5, 25, 45))
image.save(sys.argv[1], tiffinfo=ifd)
PY

validator_require_file "$img"

report="$tmpdir/info.txt"
tiffinfo "$img" >"$report"
validator_assert_contains "$report" "Make: Validator-Cam"
validator_assert_contains "$report" "Model: Model-XR-7"

python3 - <<'PY' "$img"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    make = im.tag_v2.get(271)
    model = im.tag_v2.get(272)
    assert make == "Validator-Cam", make
    assert model == "Model-XR-7", model
    print("camera", repr(make), repr(model))
PY
