#!/usr/bin/env bash
# @testcase: usage-python3-pil-multiframe-count-tiff
# @title: Pillow multiframe TIFF count
# @description: Creates a multi-frame TIFF and verifies the total frame count with Pillow iteration.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-multiframe-count-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from PIL import Image, ImageSequence
from pathlib import Path
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

path = tmpdir / "count.tiff"
a = Image.new("RGB", (2, 2), "red")
b = Image.new("RGB", (2, 2), "blue")
c = Image.new("RGB", (2, 2), "green")
a.save(path, save_all=True, append_images=[b, c])
with Image.open(path) as im:
    assert sum(1 for _ in ImageSequence.Iterator(im)) == 3; print("frames", 3)
PY
