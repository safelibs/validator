#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-multipage-seek-tell-walk
# @title: Pillow TIFF multi-page seek and tell walk
# @description: Writes a 5-page TIFF with distinct flat colors per page and walks frames with seek/tell, checking that each frame's index and dominant color match its position in the sequence.
# @timeout: 180
# @tags: usage, image, python, multipage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/five-pages.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

path = sys.argv[1]
size = (10, 8)
colors = [
    (240, 20, 20),
    (20, 240, 20),
    (20, 20, 240),
    (240, 240, 20),
    (20, 240, 240),
]
frames = [Image.new("RGB", size, c) for c in colors]
frames[0].save(path, save_all=True, append_images=frames[1:])
PY

validator_require_file "$src"

python3 - <<'PY' "$src"
import sys
from PIL import Image

expected_colors = [
    (240, 20, 20),
    (20, 240, 20),
    (20, 20, 240),
    (240, 240, 20),
    (20, 240, 240),
]

with Image.open(sys.argv[1]) as im:
    n = getattr(im, "n_frames", 1)
    assert n == 5, n
    for i in range(n):
        im.seek(i)
        assert im.tell() == i, (i, im.tell())
        assert im.size == (10, 8), (i, im.size)
        assert im.mode == "RGB", (i, im.mode)
        # The center pixel reflects the flat fill we wrote.
        center = im.getpixel((5, 4))
        assert center == expected_colors[i], (i, center, expected_colors[i])
        print("frame", i, im.tell(), center)

    # After the walk, seek back to the first frame succeeds.
    im.seek(0)
    assert im.tell() == 0
PY
