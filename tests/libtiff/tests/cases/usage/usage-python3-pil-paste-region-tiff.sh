#!/usr/bin/env bash
# @testcase: usage-python3-pil-paste-region-tiff
# @title: Pillow pastes TIFF region
# @description: Pastes a TIFF onto a larger canvas with Pillow and verifies the saved output dimensions.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-paste-region-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from io import BytesIO
from pathlib import Path
from PIL import Image
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

path = tmpdir / "paste.tiff"
canvas = Image.new("RGB", (8, 8), "black")
with Image.open(fixture) as im:
    canvas.paste(im, (1, 1))
canvas.save(path)
with Image.open(path) as im:
    assert im.size == (8, 8)
    print("paste", im.size)
PY
