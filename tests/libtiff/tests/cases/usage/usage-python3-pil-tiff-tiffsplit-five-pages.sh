#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffsplit-five-pages
# @title: Pillow TIFF tiffsplit on 5-page TIFF
# @description: Writes a 5-page TIFF with Pillow, runs tiffsplit to produce 5 single-page files, and verifies each output has exactly one frame and the dominant color matches the source page index.
# @timeout: 180
# @tags: usage, image, python, cli, multipage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/multi5.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

path = sys.argv[1]
size = (8, 6)
colors = [
    (255, 0, 0),
    (0, 255, 0),
    (0, 0, 255),
    (255, 255, 0),
    (0, 255, 255),
]
frames = [Image.new("RGB", size, c) for c in colors]
frames[0].save(path, save_all=True, append_images=frames[1:])
PY

validator_require_file "$src"
(
    cd "$tmpdir"
    tiffsplit "$src" "frag-"
)

# tiffsplit produces frag-aaa.tif .. frag-aae.tif for 5 pages.
parts=(
    "$tmpdir"/frag-aaa.tif
    "$tmpdir"/frag-aab.tif
    "$tmpdir"/frag-aac.tif
    "$tmpdir"/frag-aad.tif
    "$tmpdir"/frag-aae.tif
)
for part in "${parts[@]}"; do
    validator_require_file "$part"
done

# A sixth fragment must NOT exist - we asked for exactly 5 pages.
if [[ -f "$tmpdir/frag-aaf.tif" ]]; then
    printf 'unexpected sixth split file produced\n' >&2
    exit 1
fi

python3 - <<'PY' "${parts[@]}"
import sys
from PIL import Image

expected = [
    (255, 0, 0),
    (0, 255, 0),
    (0, 0, 255),
    (255, 255, 0),
    (0, 255, 255),
]
for i, path in enumerate(sys.argv[1:]):
    with Image.open(path) as im:
        im.load()
        n = getattr(im, "n_frames", 1)
        assert n == 1, (path, n)
        assert im.size == (8, 6), (path, im.size)
        assert im.mode == "RGB", (path, im.mode)
        assert im.getpixel((4, 3)) == expected[i], (path, im.getpixel((4, 3)), expected[i])
        print("split", path.rsplit("/", 1)[-1], im.size, n)
PY
