#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-photometric-miniswhite-bilevel
# @title: Pillow TIFF photometric miniswhite via tiffcp
# @description: Builds a 1-bit TIFF with Pillow, converts photometric to MinIsWhite (0) using tiffset, then verifies the PhotometricInterpretation tag (262) reads as 0 on reload via Pillow tag_v2.
# @timeout: 180
# @tags: usage, image, python, photometric
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/black.tiff"
dst="$tmpdir/white.tiff"

python3 - <<'PY' "$src"
from PIL import Image
import sys

size = (16, 8)
# Alternating columns -> deterministic 1-bit pattern.
pixels = bytes((255 if (x % 2 == 0) else 0) for y in range(size[1]) for x in range(size[0]))
image = Image.frombytes("L", size, pixels).convert("1")
image.save(sys.argv[1], compression="group4")
PY

validator_require_file "$src"

tiffset -s 262 0 "$src"
cp "$src" "$dst"

python3 - <<'PY' "$dst"
from PIL import Image
import sys

with Image.open(sys.argv[1]) as im:
    im.load()
    photometric = im.tag_v2.get(262)
    assert photometric == 0, photometric
    assert im.size == (16, 8), im.size
    print("miniswhite", photometric)
PY
