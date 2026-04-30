#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-subifd-tag-roundtrip
# @title: Pillow TIFF SubIFD tag (330) roundtrip via low-level tag dict
# @description: Writes a TIFF whose IFD carries a SubIFD pointer (tag 330) injected through a low-level ImageFileDirectory_v2, then reopens with Pillow and verifies tag 330 is preserved verbatim alongside the standard image tags.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/subifd.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

path = sys.argv[1]
size = (12, 10)
pixels = [
    ((x * 7) % 256, (y * 11) % 256, ((x + y) * 13) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)

# Inject SubIFD (330) as a LONG offset placeholder via the tag dict.
# Pillow does not synthesize a real sub-IFD tree, but it does serialize
# the LONG value verbatim so we can verify it round-trips.
ifd = ImageFileDirectory_v2()
ifd[330] = (0,)
image.save(path, tiffinfo=ifd)
PY

validator_require_file "$img"

python3 - <<'PY' "$img"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.size == (12, 10), im.size
    assert im.mode == "RGB", im.mode
    assert 330 in im.tag_v2, "SubIFD tag (330) missing on roundtrip"
    sub = im.tag_v2[330]
    # Pillow returns a tuple of LONGs.
    assert isinstance(sub, tuple), (type(sub), sub)
    assert sub == (0,), sub
    # Standard image tags must still be present.
    for tag in (256, 257, 258, 262, 273, 277, 278, 279):
        assert tag in im.tag_v2, ("missing", tag)
    print("subifd", sub, im.size)
PY
