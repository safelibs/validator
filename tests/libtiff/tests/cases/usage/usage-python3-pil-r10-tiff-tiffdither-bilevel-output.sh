#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-tiffdither-bilevel-output
# @title: tiffdither converts an 8-bit grayscale TIFF to 1-bit bilevel
# @description: Saves an L-mode grayscale TIFF with Pillow, runs tiffdither to produce a bilevel TIFF, and verifies tag_v2[258] BitsPerSample is 1 and Pillow opens the result in mode "1".
# @timeout: 180
# @tags: usage, tiff, python, tiffdither
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/gray.tiff"
dst="$tmpdir/bilevel.tiff"

python3 - "$src" <<'PY'
import sys
from PIL import Image
img = Image.new("L", (32, 16))
img.putdata([(x * 8 + y * 4) % 256 for y in range(16) for x in range(32)])
img.save(sys.argv[1], "TIFF")
PY

validator_require_file "$src"
tiffdither "$src" "$dst"
validator_require_file "$dst"

python3 - "$dst" <<'PY'
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    bps = im.tag_v2.get(258)
    assert bps == 1, ("BitsPerSample", bps)
    assert im.mode == "1", im.mode
    assert im.size == (32, 16), im.size
PY
