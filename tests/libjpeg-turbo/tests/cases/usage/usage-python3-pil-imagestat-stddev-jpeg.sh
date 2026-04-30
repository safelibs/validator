#!/usr/bin/env bash
# @testcase: usage-python3-pil-imagestat-stddev-jpeg
# @title: Pillow ImageStat stddev on JPEG
# @description: Decodes a JPEG with Pillow and verifies ImageStat per-channel mean and stddev match a manual computation.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imagestat-stddev-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageStat
import math
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.jpg'
base = Image.new('RGB', (4, 3))
base.putdata([
    (10, 20, 30), (40, 50, 60), (70, 80, 90), (100, 110, 120),
    (130, 30, 20), (20, 140, 40), (30, 50, 150), (200, 210, 40),
    (15, 200, 100), (220, 30, 180), (90, 160, 10), (250, 250, 250),
])
base.save(source, 'JPEG', quality=100, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (4, 3)
    pixels = list(im.convert('RGB').getdata())
    stat = ImageStat.Stat(im)
    mean = stat.mean
    stddev = stat.stddev

n = len(pixels)
manual_mean = [sum(p[i] for p in pixels) / n for i in range(3)]
manual_var = [sum((p[i] - manual_mean[i]) ** 2 for p in pixels) / n for i in range(3)]
manual_std = [math.sqrt(v) for v in manual_var]

for observed, expected in zip(mean, manual_mean):
    assert abs(observed - expected) < 1e-6, (observed, expected)
for observed, expected in zip(stddev, manual_std):
    assert abs(observed - expected) < 1e-6, (observed, expected)

assert all(s > 0 for s in stddev), stddev
print('mean', [round(v, 2) for v in mean], 'stddev', [round(v, 2) for v in stddev])
PYCASE

file "$tmpdir/input.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
