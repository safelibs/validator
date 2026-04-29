#!/usr/bin/env bash
# @testcase: usage-python3-pil-offset-tiff
# @title: python PIL offset TIFF
# @description: Exercises python pil offset tiff through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-offset-tiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageChops, ImageOps, ImageSequence, ImageStat
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.tiff'
base = Image.new('RGB', (4, 3))
base.putdata([
    (10, 20, 30), (40, 50, 60), (70, 80, 90), (100, 110, 120),
    (130, 30, 20), (20, 140, 40), (30, 50, 150), (200, 210, 40),
    (15, 200, 100), (220, 30, 180), (90, 160, 10), (250, 250, 250),
])
base.save(source, 'TIFF')

with Image.open(source) as im:
    out = ImageChops.offset(im, 1, 1)
    out.save(tmpdir / 'out.tiff', 'TIFF')
with Image.open(tmpdir / 'out.tiff') as im:
    assert im.size == (4, 3)
    print('offset', im.size)
PYCASE
