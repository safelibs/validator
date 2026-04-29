#!/usr/bin/env bash
# @testcase: usage-python3-pil-rgba-tiff
# @title: Pillow RGBA TIFF
# @description: Writes and reopens an RGBA TIFF with Pillow.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-rgba-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from PIL import Image, ImageSequence
from pathlib import Path
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

path = tmpdir / "rgba.tiff"
Image.new("RGBA", (4, 3), (255, 0, 0, 128)).save(path)
with Image.open(path) as im:
    im.load(); assert im.mode == "RGBA"; print("rgba", im.size)
PY
