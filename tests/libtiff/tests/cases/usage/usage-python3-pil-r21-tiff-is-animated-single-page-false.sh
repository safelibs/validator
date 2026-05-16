#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-tiff-is-animated-single-page-false
# @title: Pillow Image.is_animated is False for a single-page TIFF
# @description: Saves a single solid frame as a TIFF (no save_all), opens it via Image.open, and asserts n_frames equals 1 and is_animated is False, confirming the libtiff single-IFD path is correctly reported as non-animated by Pillow.
# @timeout: 60
# @tags: usage, tiff, python, multipage, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/one.tif" <<'PY'
import sys
from PIL import Image

Image.new('L', (4, 4), 128).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    assert im.format == 'TIFF', im.format
    assert im.n_frames == 1, im.n_frames
    assert im.is_animated is False, im.is_animated
    print('ok single n_frames=%d' % im.n_frames)
PY
