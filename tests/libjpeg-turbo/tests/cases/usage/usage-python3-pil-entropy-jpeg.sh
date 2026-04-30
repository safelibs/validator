#!/usr/bin/env bash
# @testcase: usage-python3-pil-entropy-jpeg
# @title: Pillow Image.entropy on JPEG
# @description: Saves a high-variance JPEG and a flat JPEG with Pillow, reopens both and verifies Image.entropy returns a finite non-negative value and that the high-variance image has strictly greater entropy than the flat image.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-entropy-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import math
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
varied_path = tmpdir / 'varied.jpg'
flat_path = tmpdir / 'flat.jpg'

# A varied gradient covers many intensity bins => high entropy.
varied = Image.new('L', (32, 32))
varied.putdata([(x * 8 + y * 5) % 256 for y in range(32) for x in range(32)])
varied.save(varied_path, 'JPEG', quality=100, subsampling=0)

# A flat mid-gray image collapses to one bin => low (near-zero) entropy.
flat = Image.new('L', (32, 32), 128)
flat.save(flat_path, 'JPEG', quality=100, subsampling=0)

with Image.open(varied_path) as im:
    im.load()
    e_varied = im.entropy()
    assert math.isfinite(e_varied)
    assert e_varied > 0.0, e_varied

with Image.open(flat_path) as im:
    im.load()
    e_flat = im.entropy()
    assert math.isfinite(e_flat)
    assert e_flat >= 0.0, e_flat

assert e_varied > e_flat, (e_varied, e_flat)
print('entropy', round(e_varied, 4), round(e_flat, 4))
PYCASE

file "$tmpdir/varied.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
