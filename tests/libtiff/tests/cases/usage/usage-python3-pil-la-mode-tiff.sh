#!/usr/bin/env bash
# @testcase: usage-python3-pil-la-mode-tiff
# @title: Pillow LA mode TIFF
# @description: Saves an LA-mode TIFF with Pillow and verifies the reloaded image preserves the grayscale-plus-alpha mode.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-la-mode-tiff"
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

path = tmpdir / "la.tiff"
Image.new("LA", (4, 3), (120, 200)).save(path)
with Image.open(path) as im:
    im.load()
    assert im.mode == "LA"
    print("la", im.size)
PY
