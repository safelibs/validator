#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-crop-save-reload
# @title: Pillow WebP crop save and reload
# @description: Opens a WebP fixture with Pillow, crops a sub-rectangle, saves the crop as a new WebP, and reloads the saved file to verify the crop dimensions and a sample pixel survive the save/reload roundtrip.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-crop-save-reload"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
from PIL import Image
import sys
im = Image.new('RGB', (12, 8), (0, 0, 0))
for y in range(8):
    for x in range(12):
        im.putpixel((x, y), ((x * 17) % 256, (y * 29) % 256, ((x + y) * 11) % 256))
im.save(sys.argv[1], 'PNG')
PY

# Encode lossless so the cropped pixel is exact after save/reload.
python3 - <<'PY' "$tmpdir/in.png" "$tmpdir/in.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.save(sys.argv[2], 'WEBP', lossless=True, method=4)
PY

python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/crop.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP'
    box = (2, 1, 9, 6)  # 7x5 crop
    cropped = im.crop(box)
    cropped.save(sys.argv[2], 'WEBP', lossless=True, method=4)
    expected = im.convert('RGB').getpixel((4, 3))  # box (2,1) + (2,2) -> (4,3)

with Image.open(sys.argv[2]) as out:
    out.load()
    assert out.format == 'WEBP', out.format
    assert out.size == (7, 5), out.size
    got = out.convert('RGB').getpixel((2, 2))
    assert got == expected, (got, expected)
    print('crop-save-reload', out.size, got)
PY

file "$tmpdir/crop.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'
