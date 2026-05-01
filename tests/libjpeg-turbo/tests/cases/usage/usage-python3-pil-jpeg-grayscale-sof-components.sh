#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-grayscale-sof-components
# @title: Pillow grayscale JPEG SOF component count
# @description: Saves an L-mode JPEG via Pillow and verifies the SOF0 marker declares exactly one component (Nf=1) for grayscale.
# @timeout: 180
# @tags: usage, jpeg, python, grayscale
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
src = Image.new('L', (16, 12))
src.putdata([(x * 16 + y) & 255 for y in range(12) for x in range(16)])

out = tmpdir / 'gray.jpg'
src.save(out, 'JPEG', quality=85)
data = out.read_bytes()

# Locate SOF0 (FFC0). Layout: FFC0 Lf(2) P(1) Y(2) X(2) Nf(1) ...
idx = data.find(b'\xff\xc0')
assert idx >= 0, 'SOF0 not found in grayscale JPEG'
nf = data[idx + 9]
assert nf == 1, f'expected Nf=1 for grayscale, got Nf={nf}'

with Image.open(out) as im:
    im.load()
    assert im.mode == 'L', f'expected mode L, got {im.mode}'
print('grayscale SOF0 Nf=1 mode=L')
PYCASE
