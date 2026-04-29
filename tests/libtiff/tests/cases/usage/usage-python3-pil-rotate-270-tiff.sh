#!/usr/bin/env bash
# @testcase: usage-python3-pil-rotate-270-tiff
# @title: Pillow rotates TIFF 270 degrees
# @description: Rotates a TIFF by 270 degrees with Pillow and verifies the swapped output dimensions.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-rotate-270-tiff"
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
    out = im.transpose(Image.Transpose.ROTATE_270)
    assert out.size == (im.size[1], im.size[0])
    print("rotate270", out.size)
PY
