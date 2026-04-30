#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-multipage-mixed-compression
# @title: Pillow TIFF multipage mixed compression via tiffcp
# @description: Writes two single-page RGB TIFFs with Pillow, applies tiffcp -c lzw to page A and tiffcp -c zip to page B, then concatenates them with tiffcp to form a single 2-page TIFF and verifies each frame's Compression tag (259) on reload (5=LZW, 8=Adobe Deflate).
# @timeout: 180
# @tags: usage, image, python, multipage, compression
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/mixed.tiff"

python3 - <<'PY' "$tmpdir/a.tiff" "$tmpdir/b.tiff"
import sys
from PIL import Image

Image.new("RGB", (16, 12), (10, 20, 30)).save(sys.argv[1])
Image.new("RGB", (16, 12), (200, 100, 50)).save(sys.argv[2])
PY

# Re-encode each page with the desired compression and concatenate.
tiffcp -c lzw "$tmpdir/a.tiff" "$tmpdir/a.lzw.tiff"
tiffcp -c zip "$tmpdir/b.tiff" "$tmpdir/b.zip.tiff"
tiffcp "$tmpdir/a.lzw.tiff" "$tmpdir/b.zip.tiff" "$img"

python3 - <<'PY' "$img"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    assert getattr(im, "n_frames", 1) == 2, im.n_frames
    im.seek(0)
    comp0 = im.tag_v2.get(259)
    assert comp0 == 5, ("page0", comp0)  # LZW
    im.seek(1)
    comp1 = im.tag_v2.get(259)
    # tiffcp -c zip writes Adobe Deflate (8). Accept the legacy code 32946
    # too in case the libtiff build emits the original Deflate code.
    assert comp1 in (8, 32946), ("page1", comp1)
    print("mixed", comp0, comp1)
PY
