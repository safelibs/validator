#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-getexif-orientation-write
# @title: Pillow JPEG getexif orientation roundtrip
# @description: Saves a JPEG with an explicit EXIF blob carrying ImageDescription and Orientation tags via Pillow and verifies getexif() returns the same tag values on reopen.
# @timeout: 180
# @tags: usage, jpeg, python, exif
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
src = Image.new('RGB', (24, 16))
src.putdata([((x * 9) & 255, (y * 17) & 255, ((x ^ y) * 5) & 255)
             for y in range(16) for x in range(24)])

exif = src.getexif()
exif[0x010E] = 'safelibs validator caption'  # ImageDescription
exif[0x0112] = 6                              # Orientation (rotate 90 CW)

out = tmpdir / 'with-exif.jpg'
src.save(out, 'JPEG', quality=85, exif=exif.tobytes())

with Image.open(out) as im:
    im.load()
    assert im.format == 'JPEG'
    got = im.getexif()
    assert got.get(0x010E) == 'safelibs validator caption', f"description mismatch: {got.get(0x010E)!r}"
    assert got.get(0x0112) == 6, f"orientation mismatch: {got.get(0x0112)!r}"

# APP1 / 'Exif' marker should appear in the encoded byte stream.
data = out.read_bytes()
assert b'Exif\x00\x00' in data[:256], 'no APP1 Exif marker in JPEG header'
print('exif tags roundtripped')
PYCASE

file "$tmpdir/with-exif.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
