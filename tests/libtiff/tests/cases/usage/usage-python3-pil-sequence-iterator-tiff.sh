#!/usr/bin/env bash
# @testcase: usage-python3-pil-sequence-iterator-tiff
# @title: python PIL sequence iterator TIFF
# @description: Exercises python pil sequence iterator tiff through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-sequence-iterator-tiff"
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

first = Image.new('RGB', (2, 2), 'red')
second = Image.new('RGB', (2, 2), 'blue')
first.save(tmpdir / 'multi.tiff', save_all=True, append_images=[second])
with Image.open(tmpdir / 'multi.tiff') as im:
    frames = list(ImageSequence.Iterator(im))
    assert len(frames) == 2
    print('frames', len(frames))
PYCASE
