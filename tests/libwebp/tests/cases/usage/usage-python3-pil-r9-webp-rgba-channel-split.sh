#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-webp-rgba-channel-split
# @title: Pillow WebP RGBA split returns four bands
# @description: Saves an RGBA image as lossless WebP, reloads it, and asserts Image.split returns four single-band images each of the original dimensions.
# @timeout: 180
# @tags: usage, python3-pil, webp
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.webp"
import sys
from PIL import Image
src = Image.new('RGBA', (16, 12), (10, 20, 30, 200))
src.save(sys.argv[1], 'WEBP', lossless=True)
PY

python3 - <<'PY' "$tmpdir/in.webp"
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == 'RGBA', im.mode
    bands = im.split()
    assert len(bands) == 4, len(bands)
    for b in bands:
        assert b.size == (16, 12), b.size
        assert b.mode == 'L', b.mode
PY
