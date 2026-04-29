#!/usr/bin/env bash
# @testcase: usage-python3-pil-bilinear-resize-tiff
# @title: Pillow bilinear resize TIFF
# @description: Resizes a TIFF fixture with bilinear resampling and verifies saved TIFF dimensions.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-bilinear-resize-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from PIL import Image, ImageSequence
from pathlib import Path
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

path = tmpdir / "bilinear.tiff"
with Image.open(fixture) as im:
    out = im.resize((5, 5), resample=Image.Resampling.BILINEAR)
    out.save(path)
with Image.open(path) as im:
    assert im.size == (5, 5); print("bilinear", im.size)
PY
