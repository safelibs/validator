#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-draft-scale-ratio
# @title: Pillow JPEG draft 1/2 scaled decode
# @description: Decodes a 64x64 JPEG with Pillow draft mode at scale 1/2 and verifies libjpeg-turbo returns a 32x32 raster via DCT scaling.
# @timeout: 180
# @tags: usage, jpeg, python, decoder
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

tmpdir = Path(sys.argv[1])
src = Image.new('RGB', (64, 64))
src.putdata([(((x + y) * 4) & 255, (x * 4) & 255, (y * 4) & 255)
             for y in range(64) for x in range(64)])
in_jpg = tmpdir / 'in.jpg'
src.save(in_jpg, 'JPEG', quality=90)

with Image.open(in_jpg) as im:
    im.draft('RGB', (32, 32))
    im.load()
    w, h = im.size
# libjpeg-turbo supports M/8 scaling for M in {1..16}; 1/2 -> 32x32 exactly.
assert (w, h) == (32, 32), f'expected 32x32 from draft 1/2, got {w}x{h}'
print('draft 1/2 ok', w, h)
PYCASE
