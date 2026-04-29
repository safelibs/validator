#!/usr/bin/env bash
# @testcase: usage-python3-pil-cmyk-tiff
# @title: Pillow CMYK TIFF
# @description: Writes and reopens a CMYK TIFF with Pillow.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-cmyk-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from PIL import Image, ImageSequence
from pathlib import Path
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

path = tmpdir / "cmyk.tiff"
Image.new("CMYK", (3, 2), (0, 128, 128, 0)).save(path)
with Image.open(path) as im:
    im.load(); assert im.mode == "CMYK"; print("cmyk", im.size)
PY
