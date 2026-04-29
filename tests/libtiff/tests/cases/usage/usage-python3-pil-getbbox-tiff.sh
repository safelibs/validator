#!/usr/bin/env bash
# @testcase: usage-python3-pil-getbbox-tiff
# @title: Pillow TIFF bounding box
# @description: Computes a bounding box for a TIFF with Pillow and verifies a valid four-value rectangle is returned.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-getbbox-tiff"
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

with Image.open(fixture) as im:
    box = im.getbbox()
    assert box is not None and len(box) == 4
    print("bbox", box)
PY
