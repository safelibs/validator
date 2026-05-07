#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-multipage-seek-tell-cycle
# @title: PIL TIFF seek/tell cycle through frames matches the seeked index
# @description: Builds a 4-page TIFF with distinct solid colors and verifies Image.seek(i) followed by Image.tell() == i for i in 0..3, asserting the libtiff IFD walking is invoked correctly through Pillow.
# @timeout: 60
# @tags: usage, tiff, python, multipage, seek
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/multi.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
frames = [Image.new('RGB', (8, 8), c) for c in [
    (255, 0, 0), (0, 255, 0), (0, 0, 255), (200, 200, 200)
]]
frames[0].save(sys.argv[1], 'TIFF', save_all=True, append_images=frames[1:])

with Image.open(sys.argv[1]) as im:
    assert im.n_frames == 4, ('n_frames', im.n_frames)
    for i in range(4):
        im.seek(i)
        assert im.tell() == i, ('tell', im.tell(), 'expected', i)
PY
