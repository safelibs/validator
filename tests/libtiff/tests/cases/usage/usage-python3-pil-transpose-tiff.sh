#!/usr/bin/env bash
# @testcase: usage-python3-pil-transpose-tiff
# @title: Pillow transposes TIFF
# @description: Flips a TIFF fixture with Pillow and verifies the output size.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-transpose-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from PIL import Image, ImageSequence
from pathlib import Path
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

with Image.open(fixture) as im:
    out = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    assert out.size == im.size; print("transpose", out.size)
PY
