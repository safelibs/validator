#!/usr/bin/env bash
# @testcase: usage-python3-pil-icc-info-tiff
# @title: Pillow TIFF info dictionary
# @description: Reads TIFF metadata through Pillow info and tag dictionaries.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-icc-info-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from PIL import Image, ImageSequence
from pathlib import Path
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

with Image.open(fixture) as im:
    print("tags", len(im.tag_v2), "info", sorted(im.info)[:3])
    assert len(im.tag_v2) > 0
PY
