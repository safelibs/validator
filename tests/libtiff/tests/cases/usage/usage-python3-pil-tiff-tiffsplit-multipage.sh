#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffsplit-multipage
# @title: Pillow TIFF tiffsplit multipage split
# @description: Writes a 3-page TIFF with Pillow, runs tiffsplit to split it, and verifies that 3 single-page output files are produced with expected name pattern and each contains exactly one frame.
# @timeout: 180
# @tags: usage, image, python, cli, multipage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/multi.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

path = sys.argv[1]
a = Image.new("RGB", (12, 10), (200, 50, 50))
b = Image.new("RGB", (12, 10), (50, 200, 50))
c = Image.new("RGB", (12, 10), (50, 50, 200))
a.save(path, save_all=True, append_images=[b, c])
PY

validator_require_file "$src"
(
    cd "$tmpdir"
    tiffsplit "$src" "page-"
)

# tiffsplit names outputs <prefix><aa>.tif: page-aaa.tif, page-aab.tif, ...
parts=("$tmpdir"/page-aaa.tif "$tmpdir"/page-aab.tif "$tmpdir"/page-aac.tif)
for part in "${parts[@]}"; do
    validator_require_file "$part"
done

# A fourth piece must NOT exist - we asked for exactly 3 pages.
if [[ -f "$tmpdir/page-aad.tif" ]]; then
    printf 'unexpected fourth split file produced\n' >&2
    exit 1
fi

python3 - <<'PY' "${parts[@]}"
import sys
from PIL import Image

for path in sys.argv[1:]:
    with Image.open(path) as im:
        im.load()
        n = getattr(im, "n_frames", 1)
        assert n == 1, (path, n)
        assert im.size == (12, 10), (path, im.size)
        assert im.mode == "RGB", (path, im.mode)
        print("split", path.rsplit("/", 1)[-1], im.size, n)
PY
