#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-sharpness-four
# @title: Pillow WebP save sharpness=4
# @description: Saves a still PNG to lossy WebP through Pillow with the WebP encoder sharpness=4 option, then verifies the round-tripped image opens with the source dimensions.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-sharpness-four"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

src = Image.new('RGB', (12, 9))
for y in range(9):
    for x in range(12):
        src.putpixel((x, y), ((x * 17) % 256, (y * 23) % 256, ((x + y) * 11) % 256))

out = tmpdir / 'sharp4.webp'
# sharpness in [0, 7]; 4 is mid-strength filter preset for the WebP encoder.
src.save(out, 'WEBP', quality=72, method=4, sharpness=4)
assert out.exists() and out.stat().st_size > 0

with Image.open(out) as im:
    assert im.format == 'WEBP', im.format
    assert im.size == (12, 9), im.size
    rgb = im.convert('RGB')
    sample = rgb.getpixel((0, 0))
    assert isinstance(sample, tuple) and len(sample) == 3, sample

print('sharpness-four ok', sample)
PYCASE
