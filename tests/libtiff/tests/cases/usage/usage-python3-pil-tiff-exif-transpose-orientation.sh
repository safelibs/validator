#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-exif-transpose-orientation
# @title: Pillow TIFF ImageOps.exif_transpose orientation 6
# @description: Saves a TIFF with Orientation=6 (rotate 270 CW) tag injected via ImageFileDirectory_v2 and verifies via tiffdump that the tag is encoded into the file, plus that ImageOps.exif_transpose returns a properly-oriented image with the expected dimensions.
# @timeout: 180
# @tags: usage, image, python, exif
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/orient6.tiff"
dump="$tmpdir/orient6.dump"

python3 - <<'PY' "$src"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

path = sys.argv[1]
size = (24, 10)
pixels = [
    ((x * 7) % 256, (y * 11) % 256, ((x + y) * 5) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
ifd = ImageFileDirectory_v2()
# Orientation tag (274) value 6 = "row 0 = right side, col 0 = top".
# Pillow auto-rotates on load, so tag_v2 won't expose 274 on reload, but
# the encoded TIFF must carry the tag and Pillow reports the post-rotation
# size, both of which we verify below.
ifd[274] = 6
image.save(path, tiffinfo=ifd)
PY

validator_require_file "$src"
tiffdump "$src" >"$dump"

# tiffdump must report the Orientation tag with value 6 we injected.
validator_assert_contains "$dump" "Orientation (274) SHORT (3) 1<6>"

python3 - <<'PY' "$src"
import sys
from PIL import Image, ImageOps

original_size = (24, 10)
with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    # Pillow honours Orientation=6 on load: width and height swap.
    assert reopened.size == (original_size[1], original_size[0]), reopened.size
    assert reopened.mode == "RGB", reopened.mode

    transposed = ImageOps.exif_transpose(reopened)
    # After ImageOps.exif_transpose the displayable dimensions match what
    # Pillow already produced, and the result is RGB.
    assert transposed.size == reopened.size, (transposed.size, reopened.size)
    assert transposed.mode == "RGB", transposed.mode
    # If exif_transpose set/cleared the orientation it must be the identity.
    new_orient = transposed.getexif().get(0x0112)
    if new_orient is not None:
        assert new_orient == 1, new_orient
    print("exif_transpose", original_size, transposed.size)
PY
