#!/usr/bin/env bash
# @testcase: usage-python3-pil-split-merge-bands-tiff
# @title: python PIL split merge TIFF
# @description: Exercises python pil split merge tiff through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-split-merge-bands-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"

python3 - <<'PY' "$case_id" "$tmpdir" "$tiff"
from pathlib import Path
from PIL import Image, ImageFilter, ImageOps
import sys

case_id, tmpdir, fixture = sys.argv[1], Path(sys.argv[2]), sys.argv[3]

with Image.open(fixture) as im:
    out = Image.merge(im.mode, im.split())
    out.save(tmpdir / 'out.tiff')
with Image.open(tmpdir / 'out.tiff') as im:
    assert im.mode == 'RGB'
    print('merge', im.mode)
PY
