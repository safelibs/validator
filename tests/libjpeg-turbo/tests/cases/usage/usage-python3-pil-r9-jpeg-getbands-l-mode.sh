#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-jpeg-getbands-l-mode
# @title: Pillow getbands on L-mode JPEG
# @description: Saves a grayscale L-mode JPEG and verifies getbands returns a single-band tuple ('L',) on reload.
# @timeout: 180
# @tags: usage, jpeg, python, bands
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from PIL import Image

out = sys.argv[1] + "/gray.jpg"
Image.new("L", (8, 8), 128).save(out, "JPEG")

with Image.open(out) as probe:
    probe.load()
    bands = probe.getbands()
    assert bands == ("L",), bands
    assert probe.mode == "L", probe.mode
print("ok", bands)
PY
