#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-tiff-is-animated-multipage-true
# @title: Pillow Image.is_animated is True for a saved 3-page TIFF
# @description: Saves three solid frames as a multipage TIFF using save_all=True, opens it via Image.open, and asserts both Image.n_frames equals 3 and Image.is_animated is True for the multi-page libtiff stream.
# @timeout: 60
# @tags: usage, tiff, python, multipage, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/anim.tif" <<'PY'
import sys
from PIL import Image

frames = [Image.new('L', (4, 4), c) for c in (10, 100, 200)]
frames[0].save(sys.argv[1], 'TIFF', save_all=True, append_images=frames[1:])

with Image.open(sys.argv[1]) as im:
    assert im.format == 'TIFF', im.format
    assert im.n_frames == 3, im.n_frames
    assert im.is_animated is True, im.is_animated
    print('ok n_frames=%d is_animated=%s' % (im.n_frames, im.is_animated))
PY
