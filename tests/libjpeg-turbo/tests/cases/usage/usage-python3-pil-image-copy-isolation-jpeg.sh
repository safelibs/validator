#!/usr/bin/env bash
# @testcase: usage-python3-pil-image-copy-isolation-jpeg
# @title: Pillow Image.copy isolation on JPEG
# @description: Opens a JPEG, copies it, mutates the copy via putpixel, and verifies the original buffer is unaffected and roundtrips identically.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-image-copy-isolation-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
out_orig = tmpdir / 'orig.jpg'
out_copy = tmpdir / 'copy.jpg'

Image.new('RGB', (8, 6), (50, 100, 150)).save(source, 'JPEG', quality=100, subsampling=0)

with Image.open(source) as im:
    im.load()
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (8, 6)
    base = im.convert('RGB')

clone = base.copy()
before = base.getpixel((2, 2))
clone.putpixel((2, 2), (250, 5, 5))
after = base.getpixel((2, 2))
mutated = clone.getpixel((2, 2))

assert before == after, (before, after)
assert mutated == (250, 5, 5), mutated
assert before != mutated, (before, mutated)

base.save(out_orig, 'JPEG', quality=100, subsampling=0)
clone.save(out_copy, 'JPEG', quality=100, subsampling=0)

with Image.open(out_orig) as im:
    assert im.format == 'JPEG'
    assert im.size == (8, 6)
    r, g, b = im.getpixel((2, 2))
    assert abs(r - 50) < 6 and abs(g - 100) < 6 and abs(b - 150) < 6, (r, g, b)

with Image.open(out_copy) as im:
    assert im.format == 'JPEG'
    assert im.size == (8, 6)
    r, g, b = im.getpixel((2, 2))
    assert r > 200 and g < 60 and b < 60, (r, g, b)
    print('orig', before, 'copy', mutated, 'roundtrip copy', (r, g, b))
PYCASE

file "$tmpdir/orig.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
