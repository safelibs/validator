#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-to-png
# @title: Pillow TIFF to PNG
# @description: Converts a TIFF fixture to PNG with Pillow and verifies PNG output.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-tiff-to-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from PIL import Image, ImageSequence
from pathlib import Path
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

path = tmpdir / "out.png"
with Image.open(fixture) as im:
    im.save(path, "PNG")
with Image.open(path) as im:
    assert im.format == "PNG"; print("png", im.size)
PY
