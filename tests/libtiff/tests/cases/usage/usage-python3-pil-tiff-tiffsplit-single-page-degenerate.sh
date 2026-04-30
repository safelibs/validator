#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffsplit-single-page-degenerate
# @title: Pillow TIFF tiffsplit on a single-page input (degenerate)
# @description: Writes a one-page TIFF with Pillow, runs tiffsplit, and verifies the degenerate case: exactly one output file (page-aaa.tif) is produced, no page-aab.tif appears, and the lone fragment round-trips through Pillow with size, mode, and solid-color pixel preserved.
# @timeout: 180
# @tags: usage, image, python, cli, multipage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/single.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

Image.new("RGB", (14, 10), (33, 144, 255)).save(sys.argv[1])
PY

validator_require_file "$src"

splitdir="$tmpdir/split"
mkdir -p "$splitdir"
(
    cd "$splitdir"
    tiffsplit "$src" "page-"
)

part="$splitdir/page-aaa.tif"
validator_require_file "$part"

if [[ -f "$splitdir/page-aab.tif" ]]; then
    printf 'unexpected second split file produced for single-page input\n' >&2
    exit 1
fi

# And no other .tif may sneak in.
count=$(find "$splitdir" -maxdepth 1 -type f -name '*.tif' | wc -l)
if [[ "$count" -ne 1 ]]; then
    printf 'expected 1 split fragment, got %s\n' "$count" >&2
    find "$splitdir" -maxdepth 1 -type f -name '*.tif' >&2
    exit 1
fi

python3 - <<'PY' "$part"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    n = getattr(im, "n_frames", 1)
    assert n == 1, ("frames", n)
    assert im.size == (14, 10), im.size
    assert im.mode == "RGB", im.mode
    assert im.getpixel((7, 5)) == (33, 144, 255), im.getpixel((7, 5))
    print("split-degenerate", im.size, n)
PY
