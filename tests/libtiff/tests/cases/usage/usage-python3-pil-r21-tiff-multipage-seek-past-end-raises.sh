#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-tiff-multipage-seek-past-end-raises
# @title: Pillow TIFF seek past the last frame raises EOFError
# @description: Saves a 2-frame TIFF, opens it, seeks to frame 1, then attempts to seek to frame 2 and asserts an EOFError is raised, validating Pillow's libtiff multipage boundary handling.
# @timeout: 60
# @tags: usage, tiff, python, multipage, seek, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/two.tif" <<'PY'
import sys
from PIL import Image

f1 = Image.new('L', (3, 3), 10)
f2 = Image.new('L', (3, 3), 20)
f1.save(sys.argv[1], 'TIFF', save_all=True, append_images=[f2])

with Image.open(sys.argv[1]) as im:
    im.seek(0)
    assert im.tell() == 0
    im.seek(1)
    assert im.tell() == 1
    try:
        im.seek(2)
    except EOFError:
        print('ok seek_eof')
    else:
        raise AssertionError('expected EOFError seeking past end')
PY
