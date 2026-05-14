#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-tiff-n-frames-single-page
# @title: Pillow single-page TIFF reports n_frames == 1
# @description: Writes a single-page RGB TIFF, reopens it with Pillow, and asserts the n_frames property equals 1, confirming libtiff's single-directory IFD chain is reported as one frame by Pillow.
# @timeout: 60
# @tags: usage, tiff, python, multipage, r17
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/single.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (6, 6), (1, 2, 3)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    n = im.n_frames
    assert n == 1, ('n_frames', n)
print('ok n_frames=1')
PY
