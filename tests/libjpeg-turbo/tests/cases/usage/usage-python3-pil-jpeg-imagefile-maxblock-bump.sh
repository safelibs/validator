#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-imagefile-maxblock-bump
# @title: Pillow JPEG ImageFile.MAXBLOCK bump
# @description: Saves a 384x384 JPEG with a long ICC payload after raising ImageFile.MAXBLOCK so Pillow can hand the libjpeg-turbo encoder a single contiguous output buffer.
# @timeout: 180
# @tags: usage, jpeg, python, encoder
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$tmpdir"
from pathlib import Path
from PIL import Image, ImageFile
import sys

tmpdir = Path(sys.argv[1])

# Bump MAXBLOCK so Pillow's _save handles a large ICC payload + qtables in
# a single buffer rather than chunking. On Pillow 10.2 the default is 65536.
default = ImageFile.MAXBLOCK
ImageFile.MAXBLOCK = max(default, 1 << 20)
try:
    W, H = 384, 384
    src = Image.new('RGB', (W, H))
    src.putdata([(((x * 13) ^ (y * 7)) & 255, (x + y) & 255, (x * y) & 255)
                 for y in range(H) for x in range(W)])

    icc = bytes((i * 5 + 11) & 0xFF for i in range(2048))
    out = tmpdir / 'big.jpg'
    src.save(out, 'JPEG', quality=92, optimize=True, icc_profile=icc)

    with Image.open(out) as im:
        im.load()
        assert im.size == (W, H)
        assert im.info.get('icc_profile') == icc, 'icc payload truncated'
    print('saved with MAXBLOCK', ImageFile.MAXBLOCK, 'size', out.stat().st_size)
finally:
    ImageFile.MAXBLOCK = default
PYCASE

file "$tmpdir/big.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
