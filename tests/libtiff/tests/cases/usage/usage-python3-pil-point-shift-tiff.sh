#!/usr/bin/env bash
# @testcase: usage-python3-pil-point-shift-tiff
# @title: Pillow point shift TIFF
# @description: Applies a point-wise channel offset to a TIFF with Pillow and verifies the saved output remains decodable.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-point-shift-tiff"
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

path = tmpdir / "point.tiff"
with Image.open(fixture) as im:
    out = im.point(lambda value: min(255, value + 5))
    out.save(path)
with Image.open(path) as im:
    assert im.size[0] > 0 and im.size[1] > 0
    print("point", im.size)
PY
