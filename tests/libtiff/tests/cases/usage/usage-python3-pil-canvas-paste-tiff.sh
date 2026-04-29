#!/usr/bin/env bash
# @testcase: usage-python3-pil-canvas-paste-tiff
# @title: python PIL canvas paste TIFF
# @description: Exercises python pil canvas paste tiff through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-canvas-paste-tiff"
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
    canvas = Image.new('RGB', (8, 6), 'white')
    canvas.paste(im, (2, 1))
    canvas.save(tmpdir / 'out.tiff')
with Image.open(tmpdir / 'out.tiff') as im:
    assert im.size == (8, 6)
    print('canvas', im.size)
PY
