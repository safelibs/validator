#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-tiff-thumbnail-shrink
# @title: Pillow thumbnail shrinks TIFF below cap
# @description: Loads a 80x60 TIFF and applies thumbnail((20, 20)) and verifies both reported dimensions are at most 20.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/big.tiff" "$tmpdir/thumb.tiff" <<'PY'
import sys
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
Image.new("RGB", (80, 60), (180, 60, 240)).save(src, "TIFF")

with Image.open(src) as im:
    im.thumbnail((20, 20))
    im.save(dst, "TIFF")

with Image.open(dst) as out:
    out.load()
    w, h = out.size
    assert w <= 20 and h <= 20, out.size
    # Original aspect ratio is 80/60 = 4/3, so thumbnail at 20 cap should be 20x15.
    assert (w, h) == (20, 15), out.size
PY
