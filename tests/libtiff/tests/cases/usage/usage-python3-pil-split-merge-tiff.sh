#!/usr/bin/env bash
# @testcase: usage-python3-pil-split-merge-tiff
# @title: Pillow split and merge TIFF
# @description: Splits a TIFF into bands with Pillow, merges the bands again, and verifies the result stays decodable.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-split-merge-tiff"
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

path = tmpdir / "merge.tiff"
with Image.open(fixture) as im:
    bands = im.split()
    merged = Image.merge(im.mode, bands)
    merged.save(path)
with Image.open(path) as im:
    assert im.size[0] > 0 and im.size[1] > 0
    print("merge", im.size)
PY
