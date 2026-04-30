#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-exif-transpose-rotate
# @title: Pillow JPEG exif_transpose rotate
# @description: Embeds EXIF Orientation=6 in a JPEG and verifies ImageOps.exif_transpose rotates dimensions accordingly.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$tmpdir"
from pathlib import Path
from PIL import Image, ImageOps, ExifTags
import sys

tmpdir = Path(sys.argv[1])
src = Image.new('RGB', (24, 12))
src.putdata([((x * 9) % 256, (y * 21) % 256, ((x + y) * 5) % 256) for y in range(12) for x in range(24)])

orientation_tag = next(k for k, v in ExifTags.TAGS.items() if v == 'Orientation')
exif = src.getexif()
exif[orientation_tag] = 6  # rotate 270 CW on display = swap w/h
out = tmpdir / 'rotated.jpg'
src.save(out, 'JPEG', quality=90, exif=exif.tobytes())

with Image.open(out) as im:
    im.load()
    assert im.size == (24, 12), f"raw size unexpectedly transformed: {im.size}"
    raw_exif = im.getexif()
    assert raw_exif.get(orientation_tag) == 6, f"orientation missing: {raw_exif!r}"
    transposed = ImageOps.exif_transpose(im)
    assert transposed.size == (12, 24), f"exif_transpose did not swap dims: {transposed.size}"
    new_exif = transposed.getexif()
    # exif_transpose strips/normalizes orientation
    assert new_exif.get(orientation_tag, 1) == 1, f"orientation not normalized: {new_exif!r}"
print('raw', im.size, 'transposed', transposed.size)
PYCASE

file "$tmpdir/rotated.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
