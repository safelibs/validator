#!/usr/bin/env bash
# @testcase: usage-python3-pil-uncompressed-tiff
# @title: Pillow uncompressed TIFF
# @description: Saves an uncompressed TIFF with Pillow and verifies the image can be reopened.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-uncompressed-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from PIL import Image, ImageSequence
from pathlib import Path
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

path = tmpdir / "raw.tiff"
Image.new("RGB", (4, 4), "green").save(path, compression="raw")
with Image.open(path) as im:
    im.load(); assert im.size == (4, 4); print("raw", im.size)
PY
