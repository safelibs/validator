#!/usr/bin/env bash
# @testcase: usage-python3-pil-imagedraw-text-jpeg
# @title: Pillow ImageDraw.text on JPEG
# @description: Renders text onto a JPEG with ImageDraw using the default font and verifies that drawn pixels darken the canvas after JPEG roundtrip.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imagedraw-text-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageDraw, ImageStat
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'out.jpg'

Image.new('RGB', (64, 32), (255, 255, 255)).save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    im.load()
    canvas = im.convert('RGB')
    base_mean = ImageStat.Stat(canvas).mean

draw = ImageDraw.Draw(canvas)
draw.text((4, 8), 'JPEG', fill=(0, 0, 0))
canvas.save(output, 'JPEG', quality=95, subsampling=0)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (64, 32)
    out_mean = ImageStat.Stat(im).mean
    # Drawing black text onto a white canvas must reduce the mean intensity.
    for o, e in zip(out_mean, base_mean):
        assert o < e - 1.0, (o, e)
    print('text mean', [round(v, 2) for v in out_mean], 'base mean', [round(v, 2) for v in base_mean])
PYCASE

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
