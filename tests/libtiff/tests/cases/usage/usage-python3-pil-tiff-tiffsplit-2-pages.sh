#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffsplit-2-pages
# @title: Pillow TIFF tiffsplit on 2-page TIFF
# @description: Writes a minimal 2-page multipage TIFF with Pillow, runs tiffsplit, and verifies exactly two single-frame outputs are produced (page-aaa.tif and page-aab.tif) with the original per-page solid colors preserved.
# @timeout: 180
# @tags: usage, image, python, cli, multipage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/two.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

path = sys.argv[1]
a = Image.new("RGB", (10, 8), (220, 30, 30))
b = Image.new("RGB", (10, 8), (30, 30, 220))
a.save(path, save_all=True, append_images=[b])
PY

validator_require_file "$src"
(
    cd "$tmpdir"
    tiffsplit "$src" "page-"
)

parts=("$tmpdir/page-aaa.tif" "$tmpdir/page-aab.tif")
for part in "${parts[@]}"; do
    validator_require_file "$part"
done

# A third piece must NOT exist - we asked for exactly 2 pages.
if [[ -f "$tmpdir/page-aac.tif" ]]; then
    printf 'unexpected third split file produced\n' >&2
    exit 1
fi

python3 - <<'PY' "${parts[@]}"
import sys
from PIL import Image

expected = [(220, 30, 30), (30, 30, 220)]
for i, path in enumerate(sys.argv[1:]):
    with Image.open(path) as im:
        im.load()
        n = getattr(im, "n_frames", 1)
        assert n == 1, (path, n)
        assert im.size == (10, 8), (path, im.size)
        assert im.mode == "RGB", (path, im.mode)
        assert im.getpixel((5, 4)) == expected[i], (path, im.getpixel((5, 4)), expected[i])
        print("split2", path.rsplit("/", 1)[-1], im.size, n)
PY
