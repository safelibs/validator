#!/usr/bin/env bash
# @testcase: usage-python3-pil-resize-nearest-tiff
# @title: Pillow nearest resize TIFF
# @description: Resizes a TIFF with nearest-neighbor sampling in Pillow and verifies the requested output dimensions.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-resize-nearest-tiff"
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

path = tmpdir / "nearest.tiff"
with Image.open(fixture) as im:
    out = im.resize((5, 5), resample=Image.Resampling.NEAREST)
    out.save(path)
with Image.open(path) as im:
    assert im.size == (5, 5)
    print("nearest", im.size)
PY
